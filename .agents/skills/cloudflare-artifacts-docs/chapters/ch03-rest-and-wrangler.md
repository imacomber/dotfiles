# Chapter 3: REST API and Wrangler

## Core Idea
Use the REST API from external systems and Wrangler for interactive administration. Keep Cloudflare control-plane authentication separate from the repo tokens returned for Git.

## Key Concepts
- **Account base**: `https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/artifacts`.
- **Namespace base**: Account base plus `/namespaces/$ARTIFACTS_NAMESPACE`.
- **V4 envelope**: JSON with `result`, `success`, `errors`, and `messages`; some lists add `result_info`.
- **Cursor pagination**: Repository and namespace lists use `limit` and `cursor`.
- **Offset pagination**: Token lists use `per_page` and `page`.
- **Raw content response**: Blob and file success responses return bytes rather than the JSON envelope.

## Authentication and Paths
Send a Cloudflare API token as `Authorization: Bearer ...`. Artifacts Read covers read routes; Artifacts Edit covers write routes. Do not use a repo Git token for these calls.

```sh
export ARTIFACTS_ACCOUNT_BASE_URL="https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/artifacts"
export ARTIFACTS_BASE_URL="$ARTIFACTS_ACCOUNT_BASE_URL/namespaces/$ARTIFACTS_NAMESPACE"
```

These fragments assume account ID, namespace, and API token are already provided securely. Validate resource names, JSON-encode dynamic request bodies, and URL-encode dynamic path/query values in application code.

## Route Map
Paths in the following table are relative to the account base, not the namespace base.

| Operation | Method and path |
| --- | --- |
| Create namespace | `POST /namespaces` with `namespace`, optional `jurisdiction` |
| List/get namespaces | `GET /namespaces`, `GET /namespaces/:namespace` |
| Delete empty namespace | `DELETE /namespaces/:namespace` |
| Create repo | `POST /namespaces/:namespace/repos` |
| List/get repos | `GET /namespaces/:namespace/repos`, `GET /namespaces/:namespace/repos/:name` |
| Delete repo | `DELETE /namespaces/:namespace/repos/:name` |
| Fork | `POST /namespaces/:namespace/repos/:name/fork` |
| Import | `POST /namespaces/:namespace/repos/:name/import` |
| Mint Git token | `POST /namespaces/:namespace/tokens` |
| List repo tokens | `GET /namespaces/:namespace/repos/:name/tokens` |
| Revoke token | `DELETE /namespaces/:namespace/tokens/:id` |

Creation body fields: `name`, optional `description`, `default_branch`, `read_only`. Fork body: new `name`, optional `description`, `read_only`, `default_branch_only`. Import body: `url`, optional `branch`, `depth`, `read_only`; its target name is in the URL.

Repository deletion returns **202 Accepted**, not a documented synchronous completion guarantee. Namespace deletion requires an empty namespace and returns 204 on deletion, 404 if missing, or 409 if repositories remain or lifecycle work is in progress.

## Content Routes
Relative to `$ARTIFACTS_BASE_URL/repos/$ARTIFACTS_REPO`:

| Read | Path | Success format |
| --- | --- | --- |
| History | `/log?ref=main&limit=10&offset=0` | JSON |
| Commit | `/commit/:hash` | JSON |
| Immediate tree children | `/tree/:hash` | JSON |
| Blob | `/blob/:hash` | Raw bytes |
| Path at ref | `/file?ref=main&path=README.md` | Bytes, `application/octet-stream` |
| Raw path with sniffed MIME | `/raw/:ref/:path` | Bytes, sniffed content type |

Content errors still use the JSON error envelope. Inspect HTTP status before treating a response as file bytes. Do not assume every successful response can be parsed as JSON.

## Worked Example: Create a repository once
Adapted from the REST quickstart. This example uses a fixed, valid name; choose a new authorized name for another run. Capture the create response once rather than re-running the POST to retrieve different fields.

```sh
CREATE_RESPONSE=$(curl --fail-with-body --silent --show-error \
  --request POST "$ARTIFACTS_BASE_URL/repos" \
  --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"name":"starter-repo","default_branch":"main"}') || exit 1
printf '%s' "$CREATE_RESPONSE" | jq -e '.success == true' >/dev/null || exit 1
ARTIFACTS_REMOTE=$(printf '%s' "$CREATE_RESPONSE" | jq -er '.result.remote') || exit 1
ARTIFACTS_TOKEN=$(printf '%s' "$CREATE_RESPONSE" | jq -er '.result.token') || exit 1
```

The checks prevent a failed request or missing fields from flowing into a Git operation. Avoid echoing the whole successful response because it contains the token. A later metadata GET recovers the remote, but not the initial secret; mint a fresh token if needed.

For existing repos, GET metadata, then POST `/tokens` with `{"repo":"starter-repo","scope":"read","ttl":3600}`. Extract `.result.plaintext`, not `.result.token`, from that second response.

## Listing Rules
- Repos: default `limit` 50, max 200; optional `search`, `sort`, `direction`. Sort values: `created_at`, `updated_at`, `last_push_at`, `name`; default created time descending. Follow `result_info.cursor`.
- Tokens: default state `active`, `per_page` 30 (max 100), `page` 1. Choose `expired`, `revoked`, or `all` when appropriate; follow offset metadata.
- Do not use a single pagination helper that assumes both APIs share one response shape.

## Wrangler Commands
```sh
npx wrangler artifacts namespaces list --json
npx wrangler artifacts namespaces get default --json
npx wrangler artifacts repos create starter-repo --namespace default --default-branch main
npx wrangler artifacts repos list --namespace default --json
npx wrangler artifacts repos get starter-repo --namespace default --json
npx wrangler artifacts repos issue-token starter-repo --namespace default --scope read --ttl 900
```

Creation also supports `--description` and `--read-only`. Deletion is `artifacts repos delete NAME --namespace NAMESPACE`; the CLI supports `--force`, but bypassing confirmation is not needed for ordinary interactive administration. Token output is secret even with `--json`.

Use the project's installed Wrangler and its current help for exact available flags. The source command page repeats global flags; those repetitions do not need to be copied into a skill.

## Anti-patterns
- **Repo-qualified token creation URL**: Minting is namespace `/tokens` with repo in the JSON body.
- **Reusing snake_case as binding options**: REST and binding shapes differ.
- **Assuming metadata GET returns a Git credential**: It returns metadata only.
- **Retrying every create failure as if absent**: `ALREADY_EXISTS` and not-ready states need inspection.
- **Logging token-bearing envelopes**: Keep credentials out of normal application logs.

## Key Takeaways
1. Separate account and namespace URL bases.
2. Check HTTP status and the JSON success envelope where applicable.
3. Respect the two pagination schemes.
4. Treat raw file responses as bytes.
5. Use explicit scope and TTL when minting Git tokens.

## Connects To
- [Chapter 2](ch02-workers.md): Binding equivalents.
- [Chapter 4](ch04-authentication-and-git.md): Credential formats.
- [Chapter 5](ch05-imports-and-forks.md): Import/fork readiness.
- [Chapter 9](ch09-data-localization.md): Explicit namespace creation.

## Sources
- [REST quickstart](https://developers.cloudflare.com/artifacts/get-started/rest-api/)
- [REST API reference](https://developers.cloudflare.com/artifacts/api/rest-api/)
- [Wrangler commands](https://developers.cloudflare.com/artifacts/api/wrangler/)

Snapshot: 2026-10-30. Shell examples are adapted with explicit failure checks.
