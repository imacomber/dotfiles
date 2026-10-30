# Chapter 4: Authentication, tokens, and Git

## Core Idea
There are three authentication paths. Workers use a configured binding; REST uses a Cloudflare API token; Git uses a repo-scoped Artifacts token. Choose credentials for the interface, then scope delegated access to the task.

## Authentication Decision Table
| Caller | Credential | Required access |
| --- | --- | --- |
| Worker calling `env.ARTIFACTS` | Runtime binding | Application authorizes its callers; no API token argument |
| External REST client | Cloudflare API token | Artifacts Read for reads, Edit for mutations |
| Git clone/fetch/pull | Artifacts repo token | `read` sufficient |
| Git push | Artifacts repo token | `write` required |
| Local Wrangler dev/deploy/types | Wrangler authentication | Separate from the Worker's runtime binding |

Your application is responsible for authorizing repository access before issuing a credential. A binding does not make an HTTP endpoint safe to expose publicly.

## Key Concepts
- **Repo scope**: A token grants access only to the repository for which it was minted.
- **Read scope**: Clone, fetch, and pull.
- **Write scope**: Read operations plus push.
- **TTL**: Token lifetime in seconds.
- **Plaintext**: Secret Git credential returned from explicit token creation.
- **Bearer form**: Full token supplied in an Authorization header.
- **Basic form**: Token secret in the password portion of an HTTPS URL.

## Token Result Shapes
| Operation | Credential field | Expiry representation |
| --- | --- | --- |
| Binding create/import/fork | `.token` string | Encoded `?expires=` suffix |
| Binding `repo.createToken()` | `.plaintext` | `.expiresAt` plus suffix |
| REST create/import/fork | `.result.token` | Encoded suffix |
| REST POST namespace `/tokens` | `.result.plaintext` | `.result.expires_at` plus suffix |

Token format is `art_v1_<40 hex>?expires=<unix_seconds>`. For Bearer authentication, keep the full string. For Basic authentication, remove only the `?expires=...` metadata; keep the `art_v1_` prefix.

The REST reference documents default scope `write`, default TTL 86,400 seconds, minimum 60, and maximum 31,536,000. Binding `createToken()` also defaults to write scope. Explicitly request `read` and a short TTL for read workflows; do not rely on permissive defaults.

## Git Technique: Prefer a Per-command Header
Assuming `ARTIFACTS_REMOTE` is the returned remote and `ARTIFACTS_TOKEN` is provided securely:

```sh
git -c http.extraHeader="Authorization: Bearer $ARTIFACTS_TOKEN" \
  clone "$ARTIFACTS_REMOTE" artifacts-clone
```

For pushing an existing checkout with an authorized write token:

```sh
git -c http.extraHeader="Authorization: Bearer $ARTIFACTS_TOKEN" \
  push "$ARTIFACTS_REMOTE" HEAD:main
```

This avoids persisting the token in the remote URL or Git config. It does not make tokens invisible to process inspection, command tracing, or verbose tooling. Avoid shell tracing and secret-bearing diagnostic output.

Use the exact API-returned remote. Its documented form is `https://<ACCOUNT_ID>.artifacts.cloudflare.net/git/<namespace>/<repo>.git`, but the returned value is the routing source of truth.

## Basic Authentication When a Tool Requires One URL
```sh
ARTIFACTS_TOKEN_SECRET="${ARTIFACTS_TOKEN%%\?expires=*}"
ARTIFACTS_AUTH_REMOTE="https://x:${ARTIFACTS_TOKEN_SECRET}@${ARTIFACTS_REMOTE#https://}"
```

Use only for a short-lived workflow that requires a self-contained URL. Artifacts ignores the non-empty username; `x` is a placeholder. Credential-bearing URLs may be persisted by Git or other tools, so prefer header authentication when supported. If a tool stores the URL, clean it up or rotate the token after the session.

## Worked Example: Review Access to an Existing Repo
1. Authenticate the reviewer in the application.
2. Resolve and authorize the exact namespace/repository pair.
3. Read the repository metadata and obtain `remote`.
4. Mint a `read` token for 900 seconds.
5. Deliver only that repo credential through the authorized handoff, not the broader Cloudflare API token.
6. Clone using the per-command header.
7. Reissue if it expires; use token revocation when ending access early is required.

Binding fragment for steps 3–4:

```js
using repo = await env.ARTIFACTS.get(authorizedRepoName);
const info = await repo.info();
const access = await repo.createToken("read", 900);
const handoff = {
  remote: info.remote,
  token: access.plaintext,
  expiresAt: access.expiresAt,
};
```

This is a capability handoff, not a public response handler. The same token cannot be reused for another session's repository.

## Protocol Support
| Operation | Support |
| --- | --- |
| Clone/fetch | Smart HTTP v1 and v2 |
| v2 upload-pack | `ls-refs` and `fetch` |
| Push | Standard v1 receive-pack |
| v2 receive-pack | Unsupported |
| Optional v1 `filter` and `include-tag` | Unsupported in the Git protocol reference |

Normal clients negotiate the protocol. Do not advertise universal support for optional Git capabilities. ArtifactFS describes its own blobless workflow; that does not mean every arbitrary partial-clone client is supported. Verify current compatibility for that combination.

## Anti-patterns
- **Cloudflare API token passed to Git**: Wrong credential type and excessively broad exposure.
- **One long-lived write token shared by all agents**: Scope and lifetime exceed their work.
- **Stripping the expiry suffix for Bearer auth**: The documented header form uses the full token.
- **Passing the full expiry-bearing string as a Basic password**: Use the secret portion.
- **Treating `write` as necessary to review**: Read-only workflows need only read scope.
- **Calling default token creation for a reader**: Defaults grant write access.

## Key Takeaways
1. Match credentials to the interface.
2. Delegate short-lived repository tokens instead of control-plane API tokens.
3. Handle `.token`, `.plaintext`, and expiry casing deliberately.
4. Prefer per-command Bearer headers.
5. Validate actual protocol support before choosing optional client features.

## Connects To
- [Chapter 2](ch02-workers.md): Binding token creation.
- [Chapter 3](ch03-rest-and-wrangler.md): REST token lifecycle.
- [Chapter 6](ch06-working-trees.md): Tools that need Basic-style remotes.

## Sources
- [Authentication](https://developers.cloudflare.com/artifacts/guides/authentication/)
- [Git protocol](https://developers.cloudflare.com/artifacts/api/git-protocol/)
- [Git client example](https://developers.cloudflare.com/artifacts/examples/git-client/)
- [REST API token reference](https://developers.cloudflare.com/artifacts/api/rest-api/#tokens)

Snapshot: 2026-10-30. Examples are adapted; process/logging cautions are implementation guidance.
