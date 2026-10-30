# Chapter 1: Repository and namespace design

## Core Idea
Use Artifacts as a versioned file tree with a Git interface. A repository is the unit of independent history, access, and cleanup; a namespace groups repositories by environment, tenant, or traffic boundary.

## Decision Rules
- **Repository per unit of work**: Give independent agents, sessions, projects, or tasks separate repositories when they need separate permissions or lifecycles. Use branches when collaborators share a lifecycle and intentionally share the same repository.
- **Fork from a reviewed baseline**: Keep starter code in a stable repository, then fork it for each session. This makes starting state consistent and changes reviewable.
- **Partition namespaces deliberately**: Start simply. Split production from development and isolate tenants or heavy workloads when ownership, jurisdiction, or namespace request limits require it.
- **Separate product files from harness metadata**: Store prompts, model output, and run context in Git notes when you want them attached to commits without editing the working tree.

Why isolation works: each repository has its own refs, history, tokens, remote URL, and durable state. A session's token cannot access another repository. Namespace naming alone does not implement your application's authorization.

## Key Concepts
- **Namespace**: A named container and routing boundary; repository names are unique within it.
- **Repository name**: Stable address component used together with the namespace across interfaces.
- **Repository ID**: Opaque identifier returned in API results, useful for records and logs.
- **Remote**: Returned HTTPS Git address; use the exact value rather than constructing a hostname.
- **Control plane**: Workers binding and REST interfaces for lifecycle, tokens, and content inspection.
- **Git data plane**: Standard Git-over-HTTPS operations for commits, trees, refs, and pushes.
- **Fork**: A new independent repository initialized from another repository's history.
- **Git notes**: Metadata under separate refs, associated with existing commits.

## Interface Selection
| Need | Choose | Reason |
| --- | --- | --- |
| Manage repos from a Worker | Workers binding | No REST token plumbing in Worker code |
| Manage repos from Rails, CI, or another host | REST API | Ordinary authenticated HTTP |
| Clone, fetch, pull, push | Git client | Existing tooling and Git semantics |
| Read a few files or inspect history | Binding or REST content APIs | Avoid cloning a working tree |
| Generate and commit files inside a Worker | isomorphic-git | Workers do not provide a Git binary |
| Fast working tree for a large sandbox repo | ArtifactFS | Hydrates blobs on demand |

The control-plane/data-plane split is a useful default, not a claim that the binding cannot read content. Current bindings expose file, blob, tree, commit, and log reads.

## Worked Example: Session repositories
Suppose a platform runs unrelated coding sessions against the same starter project.

1. Choose an environment namespace, such as `staging`.
2. Import and review a baseline once.
3. Derive a valid, unique repository name from trusted session identifiers. Validate user-derived name components before calling Artifacts.
4. Fork the baseline for each authorized session.
5. Save namespace, repository name, repository ID, and returned remote in the application's session record. Handle tokens separately as secrets.
6. Issue the session a short-lived write token only if it needs to push.
7. Review the resulting commits and clean up the session repo when its retention period ends.

Adapted binding fragment, assuming the session is authorized and `sessionRepoName` has been validated:

```js
using baseline = await env.ARTIFACTS.get("starter-repo");
const created = await baseline.fork(sessionRepoName, {
  defaultBranchOnly: true,
  readOnly: false,
});
const identity = { name: created.name, remote: created.remote };
```

`defaultBranchOnly` deliberately narrows what is copied; omit it when other branches are part of the required baseline. A fork can be temporarily unavailable; see chapter 5.

## Git Notes Technique
```sh
git notes add -m 'run: session-42' HEAD
git notes append -m 'result: checks passed' HEAD
git notes show HEAD
```

Notes have their own refs. Include `refs/notes/*` in synchronization when the metadata must travel. Notes are repository content, so avoid putting secrets in them.

## Durability and Lifecycle
Cloudflare documents synchronous replication across data centers plus asynchronous copies to object storage and snapshots. Application code does not need to implement that replication layer. This is not a documented user-facing backup restore API or a retention policy. Repositories remain stored until explicitly deleted.

Namespaces can be created explicitly; creating the first repository can also create the namespace implicitly. Older architecture prose says namespaces are not separately provisioned, while current namespace and REST references document explicit creation. Use explicit creation when jurisdiction matters, before any repository can implicitly create an unrestricted namespace.

## Anti-patterns
- **One repository as a queue for unrelated agents**: Shared refs and cleanup create conflicts and overly broad access.
- **Listing all repositories to find a known name**: Direct `get(name)` avoids unnecessary requests and pagination.
- **A default namespace for every workload forever**: One heavy workload can exhaust namespace control-plane limits.
- **Treating a namespace as a user authentication system**: Your app must decide who may create, inspect, mint tokens, and delete.
- **Reconstructing the remote URL**: Returned remotes are the authoritative routing value.

## Key Takeaways
1. Model independent work with repositories; group operating boundaries with namespaces.
2. Reuse the same namespace across Wrangler, REST, and Git workflows.
3. Keep stable identity in application records and tokens out of ordinary metadata.
4. Use content APIs for reads and Git when producing commits.
5. Plan explicit retention; storage persists until deletion.

## Connects To
- [Chapter 4](ch04-authentication-and-git.md): Repo-scoped tokens and Git access.
- [Chapter 5](ch05-imports-and-forks.md): Baselines and readiness.
- [Chapter 9](ch09-data-localization.md): Namespace jurisdiction is chosen at creation.
- [Chapter 10](ch10-operations.md): Rate limits and storage constraints.

## Sources
- [Overview](https://developers.cloudflare.com/artifacts/)
- [Get started](https://developers.cloudflare.com/artifacts/get-started/)
- [How Artifacts works](https://developers.cloudflare.com/artifacts/concepts/how-artifacts-works/)
- [Namespaces](https://developers.cloudflare.com/artifacts/concepts/namespaces/)
- [Repositories](https://developers.cloudflare.com/artifacts/concepts/repositories/)
- [Best practices](https://developers.cloudflare.com/artifacts/concepts/best-practices/)

Snapshot: 2026-10-30. Decisions and examples are synthesized from these sources.
