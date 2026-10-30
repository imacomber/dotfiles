# Chapter 5: Imports, forks, and readiness

## Core Idea
Import an external public HTTPS repository once, then fork a reviewed baseline for independent work. An import or fork result supplies identity and credentials, but follow-up access can still encounter a not-ready repository.

## Decision Rules
| Situation | Action | Trade-off |
| --- | --- | --- |
| Existing public Git baseline outside Artifacts | Import via binding or REST | Upstream availability and service import limits apply |
| Reviewed baseline already in Artifacts | Fork it | New repository has independent tokens and lifecycle |
| Need only the baseline default branch | `defaultBranchOnly: true` / `default_branch_only: true` | Omits other branches |
| Need a shallow upstream history | Import with `depth` | Historical analysis may need commits not imported |
| Need an immutable template | Consider a read-only baseline | Intentional updates require a suitable maintenance flow |
| Need an existing session repo | Direct lookup by stored name | Must handle missing/not-ready separately |

Import documentation supports **public HTTPS remotes**. Do not infer private-repository import or authenticated upstream support from the existence of `REMOTE_AUTH_REQUIRED`. Do not copy obsolete changelog claims that say any remote can be forked directly.

## Key Concepts
- **Import source**: External public HTTPS Git URL, with optional branch and shallow depth.
- **Import target**: New repository name in the chosen namespace.
- **Baseline**: Reviewed starting repository reused by sessions.
- **Fork**: New repo from existing Artifacts history, with its own remote and access tokens.
- **Readiness**: State separate from knowing a repository's name or having its creation response.
- **Collision**: A name already exists within the same namespace; not necessarily the same authorized work item.

## Binding Technique
```js
const imported = await env.ARTIFACTS.import({
  source: {
    url: "https://github.com/cloudflare/workers-sdk",
    branch: "main",
    depth: 100,
  },
  target: { name: "workers-sdk-baseline" },
});
```

The result includes `name`, `remote`, `defaultBranch`, and an initial `token`. Preserve the identity you need; keep the token secret. The binding import argument shape is nested, unlike the REST body.

After import completes and the baseline is reviewed:

```js
using baseline = await env.ARTIFACTS.get("workers-sdk-baseline");
const session = await baseline.fork(validatedSessionRepoName, {
  description: "Session workspace",
  defaultBranchOnly: true,
  readOnly: false,
});
```

Repository handles are disposable; the fork result is metadata. A new fork is not a live synchronized mirror of its source. It diverges independently.

## REST Technique
Relative to the namespace base:

```sh
curl --fail-with-body --silent --show-error --request POST \
  "$ARTIFACTS_BASE_URL/repos/workers-sdk-baseline/import" \
  --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"url":"https://github.com/cloudflare/workers-sdk","branch":"main","depth":100}'
```

The response contains a token. In real scripts, capture it and check `.success` before extracting `.result.remote` and `.result.token`; avoid printing successful token-bearing responses into logs. The illustrative curl command above displays its response when run interactively.

Fork uses `POST /repos/:sourceName/fork` with a new target `name` and optional `default_branch_only`, `description`, `read_only`.

## Readiness and Failure Handling
| Signal | Meaning | Response |
| --- | --- | --- |
| Binding list status `importing` | Import incomplete | Defer content access |
| Binding list status `forking` | Fork incomplete | Defer content access |
| `IMPORT_IN_PROGRESS` (10302) | Requested repo still importing | Retry the follow-up read after a delay |
| `FORK_IN_PROGRESS` (10303) | Requested repo still forking | Retry the follow-up read after a delay |
| REST 409 with in-progress error | Lifecycle conflict | Inspect error; do not treat every 409 as transient |
| `ALREADY_EXISTS` (10201) | Target name collision | Reconcile with app state or choose another authorized name |
| `NOT_FOUND` (10200) | Missing repo/resource | Check identity and lifecycle; do not silently recreate |
| `REMOTE_AUTH_REQUIRED` (10106) | Upstream requires auth | Choose a documented supported import source |
| `UPSTREAM_UNAVAILABLE` (10401) | Upstream cannot be reached | Diagnose upstream; bound retries |

The docs recommend short-delay retry on in-progress imports. They do not specify a universal timeout or backoff schedule. Implementation guidance: use a finite deadline and backoff appropriate to the user workflow; stop and report the specific error when it expires. Retry follow-up access instead of creating another repository each time.

## Worked Example: A Session Provisioning Flow
1. Keep namespace and target repo name in the application's session record.
2. Use a unique valid target name derived from the session identity.
3. Create or fork only when application state says this is a new workspace.
4. Persist the returned identity.
5. Attempt the next required read or Git operation.
6. If it reports importing/forking, leave the session in a provisioning state and retry access within a bounded deadline.
7. Once ready, authorize and mint the task's short-lived credential.
8. On permanent failure, record the specific cause and leave cleanup explicit.

Why this works: it distinguishes “operation accepted,” “repository exists,” and “repository ready.” A broad catch that restarts creation erases these states and can turn authentication or validation failures into repeated mutations.

## Anti-patterns
- **Import once per file read**: Reuse a reviewed baseline and stored repo identity.
- **Assuming a token implies readiness**: Follow-up access may still conflict.
- **Catch every error, then create**: Hides auth failures, name collisions, and unfinished work.
- **Silently accepting a colliding repo**: Existing resources may belong to a different session.
- **Shallow history used as a full archive**: Choose depth according to the history you actually need.

## Key Takeaways
1. Import public HTTPS sources; fork existing Artifacts baselines.
2. Keep asynchronous readiness in the application state model.
3. Reconcile collisions before reusing resources.
4. Treat the initial token as a credential, not a durable metadata field.
5. Bound retries and preserve permanent error details.

## Connects To
- [Chapter 1](ch01-foundations.md): Repository isolation.
- [Chapter 2](ch02-workers.md): Handle and result types.
- [Chapter 10](ch10-operations.md): Errors and limits.

## Sources
- [Import repositories](https://developers.cloudflare.com/artifacts/guides/import-repositories/)
- [Workers binding](https://developers.cloudflare.com/artifacts/api/workers-binding/)
- [REST API](https://developers.cloudflare.com/artifacts/api/rest-api/)
- [Errors](https://developers.cloudflare.com/artifacts/api/errors/)
- [Best practices](https://developers.cloudflare.com/artifacts/concepts/best-practices/)

Snapshot: 2026-10-30. The session state model and bounded retry policy are implementation guidance derived from documented readiness behavior.
