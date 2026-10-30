# Chapter 9: Namespace jurisdiction

## Core Idea
Choose data jurisdiction when creating a namespace, before storing repositories in it. The selected jurisdiction applies to all repositories in that namespace and cannot be changed in place.

This is a short topic because the source defines a narrow mechanism. It does not document a migration procedure or a broader compliance certification.

## Decision Rules
| Requirement | Namespace creation choice | Consequence |
| --- | --- | --- |
| Repo data stored and processed only in the European Union | `jurisdiction: "eu"` | All repos in namespace use EU jurisdiction |
| Repo data stored and processed only in the United States | `jurisdiction: "us"` | All repos in namespace use US jurisdiction |
| No selected jurisdiction | Omit `jurisdiction` | Namespace is unrestricted |
| Existing namespace has the wrong jurisdiction | Plan a different namespace and verified migration | No documented in-place jurisdiction update |
| Different tenants need different jurisdictions | Separate namespaces | Bind and route each workload to the correct namespace |

## Key Concepts
- **Jurisdiction**: Namespace restriction on where repository data is stored and processed.
- **`eu`**: Supported European Union value in this snapshot.
- **`us`**: Supported United States value in this snapshot.
- **Unrestricted**: Default when jurisdiction is omitted.
- **Namespace creation**: The point at which the jurisdiction is chosen.
- **Immutability**: Existing namespace jurisdiction cannot be changed.

## Creation Technique
Use the account-level REST route, authenticated with a Cloudflare API token with Artifacts Edit:

```sh
curl --fail-with-body --silent --show-error --request POST \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/artifacts/namespaces" \
  --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"namespace":"customer-eu","jurisdiction":"eu"}'
```

Check the HTTP result and JSON envelope before proceeding. Then bind the intended Worker to that same namespace:

```toml
[[artifacts]]
binding = "ARTIFACTS"
namespace = "customer-eu"
```

Creating the first repository can implicitly create a namespace. The guide does not document a jurisdiction parameter on repo creation or the binding configuration. When jurisdiction matters, explicitly create the namespace with that parameter first; do not let a first repo silently establish an unrestricted namespace.

## Worked Example: EU Tenant Provisioning
1. The application's tenant record requires EU repository storage/processing.
2. Select a stable, valid namespace name that matches the operating boundary.
3. Create the namespace explicitly with `jurisdiction: "eu"`.
4. Confirm the namespace identity and creation outcome before creating repositories.
5. Configure the Worker binding and external API clients to use that namespace.
6. Save and reuse returned repo remotes rather than constructing a region-specific hostname.
7. Include the tenant-to-namespace mapping in application authorization.

If an existing namespace was created unrestricted, adding a `jurisdiction` field to a local config does not change it. Stop provisioning into the wrong namespace and plan a separate target. The Artifacts sources here do not establish cross-jurisdiction fork semantics, a migration endpoint, or a zero-downtime migration guarantee. Verify the supported transfer path and validate repository contents before deleting any original data.

## Operational Boundary
The documented feature constrains repository data within the selected jurisdiction. It is not evidence that every connected system shares that restriction. Builds, sandbox execution, application logs, prompts, and external Git remotes need their own location analysis when the product requirement covers them. This is a scope distinction, not an additional Cloudflare guarantee.

Namespaces also group traffic and lifecycle ownership. Where both jurisdiction and performance isolation matter, choose names and partitions that satisfy both. Avoid casually reusing a default namespace before the product's location requirement is known.

## Anti-patterns
- **Changing jurisdiction after repository creation**: Namespace jurisdiction is immutable.
- **Assuming repo names encode residency**: A name such as `eu-project` has no documented jurisdiction effect.
- **Implicit namespace creation for a restricted workload**: No jurisdiction is supplied by the documented repo creation flow.
- **Inventing a regional Git hostname**: Use the returned remote.
- **Extending the repo guarantee to the entire app**: Other data paths have separate behavior.

## Key Takeaways
1. Choose jurisdiction before creating any repository in the namespace.
2. Use explicit namespace creation for restricted data.
3. Keep binding/API namespace names consistent.
4. Treat a changed jurisdiction requirement as a migration design problem.
5. Verify connected systems separately if the requirement extends beyond repositories.

## Connects To
- [Chapter 1](ch01-foundations.md): Namespace partitioning.
- [Chapter 3](ch03-rest-and-wrangler.md): Account-level namespace routes.
- [Chapter 7](ch07-build-and-deploy.md): Build execution is a separate system.

## Sources
- [Data localization](https://developers.cloudflare.com/artifacts/guides/data-localization/)
- [Namespaces](https://developers.cloudflare.com/artifacts/concepts/namespaces/)
- [REST namespace creation](https://developers.cloudflare.com/artifacts/api/rest-api/#create-a-namespace)

Snapshot: 2026-10-30. Migration and connected-system discussion marks limits of the documented feature, not undocumented product functionality.
