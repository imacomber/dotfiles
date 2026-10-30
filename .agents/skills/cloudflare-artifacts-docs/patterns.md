# Implementation patterns

These are synthesized from the official Artifacts docs. Chapter links provide exact APIs and source citations. Application state, bounded retries, and commit-pinning suggestions are implementation guidance, not additional service guarantees.

## Repository per independent session
**When to use:** Sessions need independent history, permissions, and cleanup.

**How:** Derive a valid unique repo name from trusted session identity; persist namespace/name/ID/remote; fork a reviewed baseline or create once. Authorize access through the application. Clean up according to the session's retention requirement.

**Trade-offs:** More lifecycle records, but isolated tokens and changes. Branches are appropriate when collaborators intentionally share repository lifecycle. See [ch01](chapters/ch01-foundations.md).

## Baseline import followed by forks
**When to use:** Many workspaces share an external starter project.

**How:** Import a public HTTPS source into a baseline repo, choose branch/depth deliberately, wait for readiness, review the baseline, then fork it into unique session repositories.

**Trade-offs:** Stable starts and reviewable diffs; shallow history and default-branch-only copies can omit required history. Forks diverge independently. See [ch05](chapters/ch05-imports-and-forks.md).

## Authorization-bound credential handoff
**When to use:** A client needs Git without control-plane credentials.

**How:** Authenticate the caller, resolve and authorize its repo, retrieve the returned remote, mint explicit read/write scope with short TTL, and hand off only that repo credential. Revoke when needed.

**Trade-offs:** Credentials expire and need refresh; prevents broad account API token exposure. `createToken()` returns `.plaintext`, unlike create result `.token`. See [ch04](chapters/ch04-authentication-and-git.md).

## Disposable content reader
**When to use:** Worker code needs a few files or Git objects.

**How:** Acquire a repo with `using`, call `info()` for metadata or `readFile({ref,path})` for path-based bytes, distinguish `null` from invalid input/not-ready exceptions, then release at scope exit.

**Trade-offs:** Avoids a checkout; not a write/commit interface. Immutable commit refs stabilize reads across moving branches. See [ch02](chapters/ch02-workers.md).

## Capture a mutation response once
**When to use:** A create/import response has multiple fields needed by later steps.

**How:** Make the mutation once, check HTTP status and envelope, extract required fields, save identity, and keep token-bearing output out of logs.

**Trade-offs:** Must explicitly recover partial provisioning state; avoids repeated creates and accidentally using fields from different responses. See [ch03](chapters/ch03-rest-and-wrangler.md).

## Readiness-aware provisioning
**When to use:** A follow-up access can occur while import or fork continues.

**How:** Track accepted/provisioning/ready/failed in app state; inspect specific errors; retry follow-up access with backoff and a finite deadline. Reconcile collisions separately.

**Trade-offs:** Requires state and retry policy but prevents a generic catch-and-create loop. Artifacts does not prescribe a universal retry interval. See [ch05](chapters/ch05-imports-and-forks.md).

## Git notes for harness context
**When to use:** Prompts, results, or run IDs should attach to a commit without changing product files.

**How:** Use `git notes add/append/show`; sync the relevant `refs/notes/*` when moving repository metadata.

**Trade-offs:** Notes are separate refs and can be omitted by ordinary sync flows. They are not a secret store. See [ch01](chapters/ch01-foundations.md).

## Startup-sensitive filesystem mounting
**When to use:** Cloning a large repo dominates sandbox startup and the host supports FUSE.

**How:** Configure ArtifactFS with the returned remote, appropriate short-lived token, chosen branch, mount root, and daemon. Measure cold reads as well as initial startup.

**Trade-offs:** Fast access to tree metadata; contents hydrate and may block. Adds mount/process operations and compatibility checks. See [ch06](chapters/ch06-working-trees.md).

## Snapshot-based CI fan-out and gated deployment
**When to use:** Custom checks and build/deploy behavior justify a Workflow.

**How:** Cache an install runner with manifest/lockfile inputs, run independent checks from that snapshot, wait for required checks, build, then deploy from the runner carrying output. Restrict deployment credentials to the deploy step.

**Trade-offs:** Requires CI SDK, Workflow, Containers, Durable Objects, R2, and configuration. Standard Workers Builds may be sufficient. See [ch07](chapters/ch07-build-and-deploy.md).

## Namespace-wide push automation
**When to use:** One platform-owned pipeline should process pushes across many repos.

**How:** Filter `cf.artifacts.repo.pushed` by namespace and omit `repo_name`. Resolve per-repo target identity from the event and app records; process the pushed ref/commit and account for retries according to the target delivery system.

**Trade-offs:** Fewer trigger definitions, but authorization and per-repo deployment mapping remain necessary. See [ch07](chapters/ch07-build-and-deploy.md) and [ch08](chapters/ch08-events.md).

## Explicit jurisdiction provisioning
**When to use:** Repository storage/processing must remain within EU or US.

**How:** Create the namespace with `jurisdiction` before any first repository can implicitly create it; configure every client to use that namespace.

**Trade-offs:** Immutable choice; changes need a separately verified migration path. Does not cover every connected system's data location. See [ch09](chapters/ch09-data-localization.md).

## Diagnose by operation and limit scope
**When to use:** Failures or latency increase.

**How:** Query Artifacts GraphQL metrics by repo, `eventKind`, operation, and time. Separate namespace management rate, repo Git rate, per-file/push constraints, and retained storage. Preserve exact API errors.

**Trade-offs:** Requires current analytics access and retention-aware queries; aggregate metrics alone do not identify every failed request. See [ch10](chapters/ch10-operations.md).
