# Artifacts decision sheet

Snapshot: 2026-10-30. Recheck live limits, prices, and installed SDK/types for real implementations.

## Choose the path
| When | Do | Because |
| --- | --- | --- |
| Independent session needs its own permissions/history/cleanup | One repo per session | Branches share repo scope |
| Sessions share starter code | Import/review baseline once, then fork | Consistent starting point |
| Known repo name | Direct `get(name)` | Avoid listing and pagination |
| Worker needs README bytes | `using repo = await get(name)`; `repo.readFile(...)` | No clone needed |
| External app manages repos | REST with Cloudflare API token | Control-plane interface |
| Runtime has Git and repo is small | Normal clone | Simplest working tree |
| Large repo delays sandbox startup | Evaluate ArtifactFS with FUSE | On-demand blob hydration |
| Worker generates commits | isomorphic-git + compatible filesystem | No Git binary in Workers |
| Standard Worker deployment | Workers Builds integration | Managed build and previews |
| Custom checks/cache/User Worker deployment | Workflow CI | Explicit pipeline control |
| EU/US restriction required | Create namespace explicitly first | Jurisdiction is immutable |

## Credential rules
| Operation | Credential/result |
| --- | --- |
| REST calls | Cloudflare API token, Artifacts Read/Edit |
| Worker binding calls | Configured runtime binding |
| Git clone/fetch/pull | Repo token with `read` |
| Git push | Repo token with `write` |
| create/import/fork | Binding `.token`; REST `.result.token` |
| Explicit token mint | Binding `.plaintext`, `.expiresAt`; REST `.result.plaintext`, `.result.expires_at` |
| Git Bearer | Full token including `?expires=` |
| Git Basic | Token before `?expires=` in password slot |

Prefer per-command `http.extraHeader`; avoid persistent credential-bearing remotes. Scope and TTL must be deliberate: default token scope is write. REST TTL: default 86,400 seconds; accepted 60–31,536,000. Authenticate/authorize app callers before returning credentials.

## Fast triage
| Symptom | Check next |
| --- | --- |
| `repo.remote` undefined after binding `get()` | Use `await repo.info()` |
| Token field missing after mint | Read `plaintext`, not `token` |
| Git cannot authenticate | Credential type, expiry, repo scope, Bearer vs Basic form |
| Push denied with working clone | `read` token cannot push; read-only repo may also matter |
| Import/fork not ready | Inspect in-progress error; bounded follow-up retry |
| Name already exists | Reconcile session identity; do not silently adopt repo |
| File read parsed as invalid JSON | Successful REST file/blob/raw routes return bytes |
| Directory read with `readFile()` returns null | Use tree API or choose a file path |
| History unexpectedly short | First-parent `log()`, limit/offset, or shallow import |
| Namespace rate pressure | Reduce management calls; partition heavy workloads |
| One repo's Git traffic hot | Per-artifact Git limit; namespace split alone does not fix it |
| Build succeeds, deploy cannot find output | Deploy from the build runner, not its sibling/parent |
| Event commit list incomplete | Inspect truncation flags; fetch required details |

## Capacity tells
- Repo below total limit can still exceed **32 MiB/file**, **64 MiB/push**, or **50,000 objects/push**.
- New repos (created from 2026-09-29): **1 GB**; earlier repos: **10 GB**. Check current limits.
- Git history remains even when files disappear from the newest tree.
- Control plane: **2,000 requests/10 seconds/namespace**; Git: **2,000/10 seconds/artifact**.
- Metrics: `artifactsEventsAdaptiveGroups`, required `accountTag`, past **31 days**; use `eventKind` to distinguish errors/actions.
- Trigger: `cf.artifacts.repo.pushed`; analytics operation: `push`; config filter: `repo_name`; event source: `repoName`.

## Stop guessing at these boundaries
- No documented in-place jurisdiction change.
- Public HTTPS imports are documented; private import support is not established here.
- Older example snippets can contradict the current binding reference.
- Event delivery/ordering guarantees belong to the actual subscription system.
- Billing timing conflicts exist in historical docs; live pricing wins.

Use chapter references from [SKILL.md](SKILL.md) for exact methods and sources.
