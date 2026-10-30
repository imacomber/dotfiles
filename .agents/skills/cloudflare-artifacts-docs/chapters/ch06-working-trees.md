# Chapter 6: Working trees in sandboxes and Workers

## Core Idea
Choose the least machinery that gives the runtime what it needs. Clone normally for small repos, use ArtifactFS when a large repo delays sandbox startup, and use isomorphic-git when Worker code must produce commits without a Git binary.

## Selection Table
| Runtime and need | Approach | Cost or limitation |
| --- | --- | --- |
| Host with Git; small or moderate repo | Normal clone | Transfers content before work starts |
| Sandbox/container/VM; large repo; fast startup | ArtifactFS | Requires FUSE; cold reads may block |
| Worker; read only a few files | Binding `readFile()` or object APIs | No local working tree |
| Worker; generate and push files | isomorphic-git plus a filesystem adapter | Working state consumes runtime memory |
| Sandbox SDK app with independent sessions | One repo per sandbox ID | App must manage identity, authorization, and retention |

Avoid adopting ArtifactFS solely because it exists. Its advantage is startup behavior for large working trees, not a simpler operational model.

## Key Concepts
- **ArtifactFS**: Mounts a repository as a local filesystem with on-demand file contents.
- **Blobless startup**: Fetch commits, trees, and refs before hydrating file contents.
- **Hydration**: Fetch a needed blob; a cold file read blocks until it is available.
- **Blob cache**: Subsequent reads can use local fetched content.
- **FUSE**: Host filesystem support required by ArtifactFS.
- **In-memory filesystem**: Adapter exposing filesystem operations to isomorphic-git inside Workers.
- **Sandbox identity**: Stable ID the app can share between the sandbox and its Artifacts repository.

## ArtifactFS Technique
The source requires a working host FUSE implementation, an existing repo's returned remote, and a repo token. Use a short-lived read token for read-only work.

```sh
go install github.com/cloudflare/artifact-fs/cmd/artifact-fs@latest
ARTIFACTS_TOKEN_SECRET="${ARTIFACTS_TOKEN%%\?expires=*}"
ARTIFACTS_AUTH_REMOTE="https://x:${ARTIFACTS_TOKEN_SECRET}@${ARTIFACTS_REMOTE#https://}"
artifact-fs add-repo \
  --name starter-repo \
  --remote "$ARTIFACTS_AUTH_REMOTE" \
  --branch main \
  --mount-root /tmp
artifact-fs daemon --root /tmp &
ls /tmp/starter-repo/
```

This is an adapted setup fragment, not an automatically executed installer. Use the host's existing process management and mount conventions for a persistent deployment. Review where credential-bearing remotes are stored. Source docs prioritize manifests, dependency files, and common source files for hydration; large binaries have lower priority.

Compatibility caveat: ArtifactFS describes blobless startup, while the Artifacts Git protocol reference says optional v1 `filter` is unsupported. These pages do not establish that every partial-clone client works. Verify current ArtifactFS/service compatibility rather than generalizing the example into arbitrary `git clone --filter` support.

## Sandbox SDK Technique
Start from the documented template when building that specific app:

```sh
npm create cloudflare@latest -- repo-per-sandbox --template=cloudflare/sandbox-sdk/examples/git-repo-per-sandbox#v0
```

Use application records to decide whether to create a new repository or reuse the existing repository for the sandbox ID. For reuse, prefer the current binding API over stale properties in the sandbox example:

```js
using repo = await env.ARTIFACTS.get(authorizedSandboxId);
const info = await repo.info();
const access = await repo.createToken("write", 3600);
const tokenSecret = access.plaintext.split("?expires=")[0];
const authenticatedRemote =
  `https://x:${tokenSecret}@${info.remote.slice("https://".length)}`;
await sandbox.setEnvVars({ ARTIFACTS_GIT_REMOTE: authenticatedRemote });
```

Assumptions: `sandbox` is the authorized session's Sandbox SDK instance, the ID is valid, and this session needs push capability. The SDK example obtains it with `getSandbox(env.Sandbox, sandboxId)`. For a new repository, use the create result's `remote`, `defaultBranch`, and `token`. Persist identity, not the expiring authenticated URL, in the ordinary session record.

## isomorphic-git Technique
The source example installs `isomorphic-git`, imports `isomorphic-git/http/web`, and supplies a `MemoryFS` adapter. Do not copy its statement that bindings cannot read files: current binding APIs do support reads. Git remains necessary for producing and pushing commits.

Adapted core sequence, assuming authorized `created` metadata and an initialized, compatible `fs` adapter are supplied:

```js
import git from "isomorphic-git";
import http from "isomorphic-git/http/web";

const dir = "/workspace";
await git.init({ fs, dir, defaultBranch: "main" });
await fs.promises.writeFile(`${dir}/README.md`, "# Session output\n");
await git.add({ fs, dir, filepath: "README.md" });
const commit = await git.commit({
  fs, dir,
  message: "Save session output",
  author: { name: "Session agent", email: "agent@example.com" },
});
const pushed = await git.push({
  fs, http, dir, url: created.remote, ref: "main",
  onAuth: () => ({ username: "x", password: created.token.split("?expires=")[0] }),
});
```

This is a fragment, not a self-contained Worker. The filesystem adapter must provide the operations isomorphic-git needs. The source's helper includes read/write, directories, unlink/rmdir, stat/lstat, UTF-8 encoding, and binary data handling. Load the original example before implementing an adapter; do not invent a placeholder `MemoryFS` import that does not exist in the project. Use an existing compatible adapter where available.

## Worked Example: Choosing a Workspace for an Agent
An agent edits a small starter repo in a sandbox. Start with a normal clone and a session-scoped write token. If measured clone time dominates startup for large baselines, evaluate ArtifactFS with the actual host's FUSE support and cold-read workload. If no sandbox is required and a Worker merely generates a small file tree, isomorphic-git can commit it in memory. If the Worker only serves README content, use `readFile()` and avoid both a filesystem adapter and a clone.

The choice follows the runtime's needed artifact: bytes, a working tree, or new Git commits. It should not begin with a preferred library.

## Anti-patterns
- **Copying a full filesystem helper for one read**: The binding already offers file reads.
- **Creating a repo on every incoming request**: Production sessions usually have a stable identity and lifecycle.
- **Using `.remote` directly on `get()`**: Current handles require `info()`.
- **Sending a write credential to every sandbox**: Read-only sessions should receive read scope.
- **Assuming hydration removes network latency**: Cold reads still block.

## Key Takeaways
1. Start with normal Git when the runtime supports it and repo size permits.
2. ArtifactFS trades clone startup for on-demand reads and operational dependencies.
3. Align sandbox and repository identity through application state.
4. Use current handle semantics even when adapting older examples.
5. Keep in-memory Git workloads within Worker resource limits.

## Connects To
- [Chapter 2](ch02-workers.md): Direct content reads.
- [Chapter 4](ch04-authentication-and-git.md): Basic token conversion.
- [Chapter 10](ch10-operations.md): Service size limits.

## Sources
- [ArtifactFS](https://developers.cloudflare.com/artifacts/guides/artifact-fs/)
- [Sandbox SDK + Artifacts](https://developers.cloudflare.com/artifacts/examples/sandbox-sdk-artifacts/)
- [isomorphic-git example and filesystem helper](https://developers.cloudflare.com/artifacts/examples/isomorphic-git/)
- [Current Workers binding reference](https://developers.cloudflare.com/artifacts/api/workers-binding/)
- [Git protocol](https://developers.cloudflare.com/artifacts/api/git-protocol/)

Snapshot: 2026-10-30. Selection reasoning and corrected handle usage are synthesized implementation guidance.
