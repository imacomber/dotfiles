---
name: cloudflare-artifacts-docs
description: "Use when building with Cloudflare Artifacts: repository and namespace design, Workers bindings, REST or Wrangler management, repo-scoped Git access, imports and forks, ArtifactFS, sandboxes, push events, and deployment. Includes implementation guidance derived from the official Artifacts documentation."
---

# Cloudflare Artifacts: implementation toolkit

**Source:** Cloudflare Developers, Artifacts documentation. **Snapshot:** 2026-10-30. **Coverage:** 26 Markdown pages organized into 10 topic chapters. Technical content, focused on building with Artifacts.

## Start Here
Read the chapter for the task before implementing its API calls. Chapter references contain exact argument shapes, return values, failure behavior, and adapted examples. Load only the relevant chapters.

- No topic specified: use the core rules below and [cheatsheet](cheatsheet.md).
- A topic or `chNN` specified: follow the chapter and topic indexes.
- Existing project: reuse its auth, HTTP client, error handling, configuration, and dependencies. This skill does not prescribe an application framework or authorize cloud mutations.
- Current limits, pricing, SDK versions, beta status, or deployments: verify the relevant official page and the target project's installed types/configuration. This is a dated documentation snapshot.

## Core Rules

### 1. Choose the interface for the needed artifact
Use the **Workers binding** for repo lifecycle, tokens, and content reads within a Worker. Use **REST** for external applications, including Rails and external CI. Use **Git over HTTPS** to clone, fetch, pull, and push commits. For a few file reads, avoid a whole checkout: current bindings and REST expose content APIs.

If Worker code needs to produce commits, use isomorphic-git with a compatible filesystem adapter. For a large sandbox working tree where startup time matters, evaluate ArtifactFS; for smaller repos, normal cloning is simpler.

### 2. Use repositories for independent work, namespaces for operating boundaries
Give independent agents, sessions, user tasks, or projects their own repositories when access, history, or cleanup must be separate. Use branches when collaborators intentionally share the same repository lifecycle. Fork reviewed baselines instead of rebuilding starter trees for every session.

Namespaces group environments, tenants, jurisdictions, or traffic shards. Repo names are unique within a namespace. Reuse stable namespace/name identity across bindings and REST, and save the API-returned repo ID/remote as needed. Use direct lookup when the name is known; do not scan list pages to rediscover it.

### 3. Keep three authentication paths separate
| Interface | Authentication | Important distinction |
| --- | --- | --- |
| Worker runtime binding | Configured `artifacts` binding | No API token argument to `env.ARTIFACTS` |
| REST control plane | Cloudflare API token | Artifacts Read or Edit permissions |
| Git data plane | Repo-scoped Artifacts token | `read` for clone/fetch/pull; `write` for push |

Authorize the application caller before creating resources, returning repo contents, or minting tokens. A demo endpoint that omits app authentication is not ready to expose. Delegate short-lived repo credentials, not the broader Cloudflare API token. Specify scope and TTL explicitly; token creation defaults can grant write access.

### 4. Respect binding handle and result shapes
`create()`, `import()`, and `fork()` return metadata with an initial **`token` string**. `get(name)` returns a **disposable repository capability**, not metadata:

```js
using repo = await env.ARTIFACTS.get(authorizedRepoName);
const info = await repo.info();
const access = await repo.createToken("read", 900);
```

Here `info.remote` is metadata, and `access.plaintext` is the Git credential; binding expiry is `expiresAt`. REST explicit token creation returns `result.plaintext` and `result.expires_at`. Do not interchange these with creation response `token` fields.

Generate binding types with `wrangler types` in the actual project. The snapshot binding reference requires Wrangler 4.145.0+ for type generation and remote local Blob APIs; verify live requirements before upgrading.

### 5. Use current content APIs and handle missing results
Binding `readFile({ref, path})` returns a MIME-typed `Blob` or `null`; empty ref/path is invalid input. `readBlob(hash)` returns an untyped Blob or `null`. `readTree(hash)` returns immediate children, not a recursive tree. `log()` follows first parents, newest first, and unresolved refs return an empty array.

REST blob/file/raw successes return bytes. Errors still use JSON envelopes. Check HTTP status before interpreting content, and encode dynamic paths/query parameters with the platform's URL tools.

### 6. Use returned remotes and the right token form
Prefer per-command Git headers:

```sh
git -c http.extraHeader="Authorization: Bearer $ARTIFACTS_TOKEN" \
  clone "$ARTIFACTS_REMOTE" artifacts-clone
```

Bearer uses the **full** `art_v1_<40 hex>?expires=<unix_seconds>` string. Tools that require Basic auth need the token secret without the `?expires=...` suffix in the password slot, with any non-empty username. Keep credentials out of persistent remotes and logs when possible. Header arguments can still be exposed by tracing or process inspection.

### 7. Distinguish acceptance from readiness
Import public HTTPS remotes through the documented import interface; do not assume private import is supported. A returned import/fork result does not prove the repo is ready for subsequent access. Handle `IMPORT_IN_PROGRESS`, `FORK_IN_PROGRESS`, or matching REST conflict errors with bounded follow-up retries. Name collisions, validation failures, auth errors, and missing repos are separate conditions.

Track session provisioning state in application records. Avoid broad catches that turn every lookup failure into another create request.

### 8. Choose jurisdiction before first repository creation
Explicitly create a namespace with `jurisdiction: "eu"` or `"us"` when required. All repositories in it inherit that restriction; it cannot be changed after namespace creation. Omission means unrestricted. First repo creation can implicitly create a namespace, so it must not get ahead of the intended jurisdiction configuration.

The repo data restriction does not establish the location behavior of external sandboxes, CI, logs, or the rest of the application.

### 9. Use managed deployment unless custom orchestration is needed
For standard Worker build/deploy and previews, start with the Workers Builds integration. Use a custom Workflows/CI pipeline for concrete needs such as runner caching, custom checks, credentials, or User Worker deployment.

Push trigger type is `cf.artifacts.repo.pushed`. Filter configuration uses `namespace` and optional `repo_name`; event source fields use `namespace` and `repoName`. Pin work to the event's target commit, handle truncated commit details, and verify delivery guarantees in the chosen subscription system. Gate deployment on required checks and preserve the runner containing the build output.

### 10. Diagnose the actual limit and keep dated facts dated
Control-plane limits are per namespace; Git request limits are per repository. File, push, object count, total repo storage, and account storage are separate constraints. Git history consumes space even when the latest working tree is small.

Use the `artifactsEventsAdaptiveGroups` GraphQL dataset for operations, latency, and errors, with `accountTag` and a time window within its documented retention. Its `eventType: "push"` is not the subscription type `cf.artifacts.repo.pushed`.

Check [live limits](https://developers.cloudflare.com/artifacts/platform/limits/) and [pricing](https://developers.cloudflare.com/artifacts/platform/pricing/) before planning capacity or quoting costs.

## Chapter Index
| # | Topic | Read when |
| --- | --- | --- |
| [ch01](chapters/ch01-foundations.md) | Repositories and namespaces | Designing isolation, identity, baselines, metadata, or retention |
| [ch02](chapters/ch02-workers.md) | Workers binding | Configuring bindings, managing handles, reading files/history |
| [ch03](chapters/ch03-rest-and-wrangler.md) | REST and Wrangler | Implementing HTTP clients, pagination, lifecycle routes, CLI admin |
| [ch04](chapters/ch04-authentication-and-git.md) | Authentication and Git | Choosing credentials, token fields, TTL, protocol behavior |
| [ch05](chapters/ch05-imports-and-forks.md) | Imports and forks | Provisioning baselines and handling not-ready states |
| [ch06](chapters/ch06-working-trees.md) | Workspace runtimes | Choosing clone, ArtifactFS, Sandbox SDK, or isomorphic-git |
| [ch07](chapters/ch07-build-and-deploy.md) | Build and deploy | Selecting managed builds or implementing custom CI |
| [ch08](chapters/ch08-events.md) | Event automation | Parsing lifecycle/push events and wiring consumers |
| [ch09](chapters/ch09-data-localization.md) | Data localization | Choosing immutable namespace jurisdiction |
| [ch10](chapters/ch10-operations.md) | Operations | Limits, errors, metrics, pricing, and historical changes |

## Topic Index
- **ArtifactFS, blobless clone, FUSE, hydration** → ch06
- **Authentication, Basic auth, Bearer, credentials** → ch04
- **Baselines, fork, import, readiness** → ch01, ch05
- **Bindings, Blob, capability, Disposable, `using`** → ch02
- **Build output, cache, CI, deployment, User Workers** → ch07
- **Changelog, billing, storage limits** → ch10
- **Commit history, file reads, Git objects, MIME** → ch02, ch03
- **Errors, conflicts, retries** → ch05, ch10
- **Event subscriptions, pushed, truncation** → ch08
- **Git notes, prompts, metadata** → ch01
- **GraphQL, metrics, latency, rate limits** → ch10
- **Identity, isolation, namespaces, repository names** → ch01
- **isomorphic-git, MemoryFS, Sandbox SDK** → ch06
- **Jurisdiction, residency, EU, US** → ch09
- **Pagination, REST envelopes, raw responses** → ch03
- **Read-only, scope, tokens, TTL, revocation** → ch04
- **Wrangler, generated types, remote local development** → ch02, ch03

## Supporting Files
- [Cheatsheet](cheatsheet.md): decision tables and failure triage.
- [Patterns](patterns.md): reusable implementation techniques.
- [Glossary](glossary.md): terms with chapter pointers.
- [Source map](chapters/sources.md): all 26 source pages, fingerprints, and known documentation conflicts.

## Scope and Limits
This is an independent synthesis of the official Artifacts docs, not an official Cloudflare skill. Code is adapted and identified as fragments where surrounding project resources are required. It has not been exercised against a live account. It does not contain account credentials or authorize deployments.

Current reference pages take precedence over older examples and historical changelog snippets. Known conflicts include binding file-read support, `get()` handle metadata, namespace creation, protocol filtering, and billing start dates; see the source map before relying on older examples. Non-text image content was not inspected; diagram alt text and surrounding prose were available. Follow-up documentation for connected products is linked where needed and is not claimed as part of the 26-page corpus.
