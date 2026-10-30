# Chapter 7: Build and deploy on push

## Core Idea
Use the Workers Builds Artifacts integration for standard Worker deployment. Build a custom Workflows pipeline only when you need custom checks, sandbox caching, retry policy, credentials, or Workers for Platforms deployment.

## Decision Rules
| Need | Choose | Why |
| --- | --- | --- |
| Standard build/deploy commands for one Worker | Workers Builds integration | Existing managed integration |
| Previews from non-production branches | Workers Builds integration | Explicitly supported preview workflow |
| Several independent checks or custom runner policy | Custom Workflows pipeline | Pipeline code controls dependencies and gating |
| Deploy User Workers into a dispatch namespace | Custom pipeline from the guide | Can invoke Workers for Platforms deployment |
| One platform pipeline across many customer repos | Namespace-filtered push trigger | Shared definition; separate run per push |

The Artifacts guide links to Workers Builds setup; that integration's full configuration is outside this source snapshot. Read its live documentation when implementing it.

## Key Concepts
- **Push event**: `cf.artifacts.repo.pushed`, identifies repository, ref, and changed commits.
- **Workflow instance**: One execution of the custom CI workflow.
- **Runner**: Isolated sandbox executing a command and collecting logs, status, and files.
- **Cached runner**: Reusable sandbox snapshot keyed by dependency inputs.
- **Dependency graph**: Later work starts only after required predecessor runners succeed.
- **Dispatch namespace**: Workers for Platforms target for User Workers.
- **Credential scope**: Deployment credentials available only where needed.

## Custom Pipeline Technique
The guide uses the `@cloudflare/ci` SDK and a project-local `./src/pipeline` module. That module is part of the surrounding CI project, not a built-in import guaranteed to exist in a new Worker. Set up the SDK/template and its bindings before adapting the pipeline fragment.

1. A Git push emits the event.
2. The configured event target starts a Workflow instance.
3. CI checks out the event's commit.
4. Install dependencies with the relevant lockfiles as cache inputs.
5. Branch independent checks from the installed snapshot.
6. Gate deployment on all required checks and the correct build output.
7. Inspect runner logs through Workflow observability when a step fails.

The source's runners can retry according to step configuration. Dependent runners wait for retry success; exhausting retries terminates the workflow as `Errored`. Choose bounded retries for the workload rather than restarting the entire pipeline blindly.

## Trigger Configuration Fragment
This fragment belongs in a Worker that already defines the target Workflow:

```json
{
  "triggers": {
    "events": [
      {
        "type": "cf.artifacts.repo.pushed",
        "filter": { "namespace": "CI", "repo_name": "my-repo" },
        "targets": [{ "type": "workflow", "workflow_name": "ci-workflow" }]
      }
    ]
  }
}
```

Keep `repo_name` to scope to one repository. Omit it, keeping `namespace`, to apply the pipeline to every repo in that namespace. Each push still creates a separate Workflow instance. The namespace filter must match the actual repository namespace; do not leave a copied `CI` value when the binding uses another namespace.

## Required Surrounding Resources
| Resource | Role |
| --- | --- |
| Artifacts binding | Access repositories |
| Workflow binding/class | Run the CI definition |
| Container and Durable Object bindings | Sandbox runners |
| R2 bucket binding | Cached sandbox snapshots |
| `nodejs_compat` flag in source example | Runtime compatibility for that CI project |
| Observability configuration | Inspect per-run status and command output |

Names such as `CiSandbox`, `SANDBOX`, `CI_WORKFLOW`, and `BACKUP_BUCKET` come from the guide's project. Align exported class names, binding names, Dockerfile, and configuration with the actual project; a trigger fragment alone does not create a working CI installation.

## Worked Example: Check, Build, Then Deploy
Adapted pipeline body. `ci` is supplied by the configured CI SDK. Project scripts are illustrative and must match the target repository.

```js
const deps = await ci.runner({
  name: "install",
  command: "bun install --frozen-lockfile",
  cache: { inputs: ["package.json", "bun.lock"] },
});
await Promise.all([
  deps.runner({ name: "lint", command: "bun run lint" }),
  deps.runner({ name: "test", command: "bun run test" }),
  deps.runner({ name: "typecheck", command: "bun run typecheck" }),
]);
const built = await deps.runner({ name: "build", command: "bun run build" });
await built.runner({ name: "deploy", command: "bun wrangler deploy" });
```

This adaptation preserves the build runner as the parent of deployment. The source shows independent child runners branching from a shared installed snapshot. If deployment needs generated files, they must come from the runner that built them; do not assume sibling runner files are merged into the shared parent. Alternatively, let the deploy command build its own output if the project explicitly supports that flow. Confirm this behavior against the current SDK when implementing.

Cache keys should include the files that actually determine dependency installation. A package manifest alone may miss lockfile changes. Reusing one installed snapshot across checks saves repeated installs, but it does not prove the dependency versions are current or the project passed checks.

## Deployment Targets
- Worker: final command `wrangler deploy`.
- User Worker: `wrangler deploy --dispatch_namespace <DISPATCH_NAMESPACE>`.
- Cross-account deployment: source uses `cloudflareCredentials.accountId`; its note says extra credentials are required when deploying to a different account from the CI Workflow.

Do not expose deployment credentials to user-authored install, lint, or test commands. Keep them at the deployment boundary and authorize which repo/ref may deploy to which target. This follows the guide's stated credential-isolation goal; exact credential configuration should follow the current SDK.

## Anti-patterns
- **Custom CI for standard deployment without a concrete need**: Adds Workflows, Containers, R2, and code to maintain.
- **Deploying before required checks complete**: A failed check must stop deployment.
- **Deploying from the wrong snapshot**: Build outputs may exist only in a child runner.
- **Namespace-wide deployment without a repo-to-target mapping**: One shared definition still needs correct tenant and deployment identity.
- **Treating the local `pipeline` import as a package**: The source fragment depends on surrounding project code.

## Key Takeaways
1. Prefer Workers Builds for standard Worker builds and previews.
2. Use custom Workflows when requirements justify the extra resources.
3. Cache dependency installs using real dependency inputs.
4. Gate deployment and preserve the build-output lineage.
5. Restrict credentials to authorized deployment work.

## Connects To
- [Chapter 8](ch08-events.md): Event type and payload fields.
- [Chapter 6](ch06-working-trees.md): Sandboxed execution.
- [Chapter 10](ch10-operations.md): Observability and operational limits.

## Sources
- [Build and deploy Artifacts repos](https://developers.cloudflare.com/artifacts/guides/build-and-deploy-on-push/)
- [Workers Builds integration, linked follow-up](https://developers.cloudflare.com/workers/ci-cd/builds/git-integration/artifacts-integration/)

Snapshot: 2026-10-30. The follow-up integration page was linked by the source, not included in the extracted corpus. Build-output lineage guidance is an explicitly identified inference from isolated runner snapshots.
