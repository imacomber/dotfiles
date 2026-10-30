# Chapter 2: Workers bindings and content access

## Core Idea
Use `env.ARTIFACTS` for repository management and direct content reads from a Worker. Distinguish creation results from disposable repository capabilities: `create()` returns metadata; `get()` returns a handle whose metadata comes from `info()`.

## Setup Technique
Add to the project's existing Wrangler configuration:

```toml
[[artifacts]]
binding = "ARTIFACTS"
namespace = "default"
```

Then generate types:

```sh
npx wrangler types
```

The generated environment includes `ARTIFACTS: Artifacts`. Treat the project's generated `worker-configuration.d.ts` as authoritative for installed binding types. The 2026-10-30 snapshot requires Wrangler **4.145.0 or later** for Artifacts type generation and Blob-returning methods with remote local bindings. Check the current requirement before changing dependencies. Set `remote = true` only when local development should reach the real Artifacts service.

Keep the project's compatibility date deliberate; a date in this snapshot is not a permanent required date.

## Key Concepts
- **Binding**: Runtime capability configured in Wrangler; Worker calls do not pass a Cloudflare API token.
- **Creation result**: Metadata including `name`, `remote`, `defaultBranch`, and initial `token`.
- **Repository capability**: Disposable RPC handle returned by `get(name)`.
- **`info()`**: Fresh metadata lookup on a repository capability.
- **`using`**: Releases a disposable repository handle at scope exit.
- **Blob**: Binary response object; path reads supply MIME type while object reads do not.
- **Ref**: Branch, tag, or commit identifier used for content resolution.

## Namespace Methods
| Call | Important arguments | Result or behavior |
| --- | --- | --- |
| `create(name, opts?)` | `description`, `readOnly`, `setDefaultBranch` | Metadata and initial token string |
| `get(name)` | Known repository name | Disposable `ArtifactsRepo`; throws if missing or not ready |
| `list(opts?)` | `limit`, `cursor` | `repos` and continuation `cursor`; statuses include `ready`, `importing`, `forking` |
| `import(params)` | `source: {url, branch?, depth?}`, `target: {name, opts?}` | Creation-style result |
| `delete(name)` | Known repository name | `Promise<boolean>` |

Do not interchange REST field names with binding arguments. Binding creation uses `setDefaultBranch`; REST uses `default_branch`.

## Repository Capability Methods
| Call | Semantics |
| --- | --- |
| `info()` | Current metadata; `NOT_FOUND` if deleted |
| `createToken(scope?, ttl?)` | Structured result with `plaintext`, `expiresAt`; scope defaults to `write` |
| `listTokens()` | Token listing with `total` and `tokens` |
| `revokeToken(tokenOrId)` | Revoke using token or ID; boolean result |
| `fork(name, opts?)` | New metadata result; options include `description`, `readOnly`, `defaultBranchOnly` |
| `log({ref?, limit?, offset?})` | Newest-first first-parent history; default `HEAD`, limit 50, max 1000, offset 0 |
| `readCommit(hash)` | Commit metadata or `null` |
| `readTree(hash)` | Immediate children only, or `null` |
| `readBlob(hash)` | Untyped `Blob` or `null`; requires lowercase 40-character Git SHA-1 |
| `readFile({ref, path})` | MIME-typed `Blob` or `null`; repository-relative non-empty path |

Unresolvable `log()` refs produce an empty array. `readFile()` returns `null` for missing files and directories, but throws `INVALID_INPUT` for empty `ref` or `path`. A missing object and invalid input are different outcomes; preserve that distinction.

## Worked Example: Serve a README without cloning
This adapted helper operates on a repository the application has already authorized. It is not a public route or a substitute for checking access.

```js
async function readAuthorizedReadme(artifacts, repoName, ref) {
  using repo = await artifacts.get(repoName);
  const file = await repo.readFile({ ref, path: "README.md" });
  if (file === null) {
    return new Response("Not found", { status: 404 });
  }
  return new Response(file, {
    headers: { "content-type": file.type },
  });
}
```

1. Resolve the application's user/session to an allowed repository.
2. Use `get()` for the disposable capability.
3. Read by path when that is the desired interface; avoid manually walking Git trees.
4. Treat a missing file as missing, not as an empty successful response.
5. Release the capability even if the read fails; scoped `using` handles this.

For a stable review or build, use an immutable commit ref rather than a moving branch. This is an implementation inference from Git ref semantics, not an additional Artifacts guarantee.

## Worked Example: Create and delegate access
```js
const created = await env.ARTIFACTS.create(validatedRepoName, {
  setDefaultBranch: "main",
  readOnly: false,
});
using repo = await env.ARTIFACTS.get(created.name);
const readAccess = await repo.createToken("read", 900);
```

`created.token` is an initial credential. `readAccess.plaintext` is a newly minted credential with `readAccess.expiresAt`. Return secrets only through an authorized access flow, and retain or revoke the initial credential according to the application's needs. Creation alone does not write a first commit; use Git to populate the repository.

## Anti-patterns
- **Reading `repo.remote` after `get()`**: Call `(await repo.info()).remote` instead.
- **Assuming `createToken()` returns a string**: Read `.plaintext`.
- **Keeping repository capabilities beyond request scope**: They are disposable RPC resources.
- **Returning write tokens from an unauthenticated demo endpoint**: Docs omit app authentication for brevity; production routes need it.
- **Treating all read failures as 404**: Missing objects, not-ready repositories, and invalid inputs need different handling.

## Key Takeaways
1. Generate binding types in the target project.
2. Use `using` for repository capabilities and `info()` for metadata.
3. Prefer `readFile()` for path reads and `readBlob()` for exact object reads.
4. Scope and expire delegated credentials explicitly.
5. Use Git to write commits; the current binding reference documents read APIs, not a file-write API.

## Connects To
- [Chapter 3](ch03-rest-and-wrangler.md): HTTP equivalents and field-name differences.
- [Chapter 4](ch04-authentication-and-git.md): Token result formats.
- [Chapter 6](ch06-working-trees.md): Committing inside Workers with isomorphic-git.

## Sources
- [Workers setup](https://developers.cloudflare.com/artifacts/get-started/workers/)
- [Workers binding reference](https://developers.cloudflare.com/artifacts/api/workers-binding/)

Snapshot: 2026-10-30. Examples are adapted from the reference, with application authorization kept explicit.
