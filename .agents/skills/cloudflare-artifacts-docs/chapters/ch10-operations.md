# Chapter 10: Limits, metrics, errors, and pricing

## Core Idea
Plan capacity around the scope of each limit and diagnose using operation type, repository identity, and latency. Treat prices, beta status, billing dates, and version requirements as dated facts to verify before implementation decisions.

## Limits Snapshot — 2026-10-30
The limits page was last updated 2026-10-28.

| Constraint | Documented value | Practical response |
| --- | --- | --- |
| Control-plane requests | 2,000 per 10 seconds per namespace | Separate heavy workloads; avoid repeated listings |
| Git requests | 2,000 per 10 seconds per artifact | Per-repo pressure differs from namespace control-plane pressure |
| Repo storage | 1 GB for repos created on/after 2026-09-29 | Budget history as well as checked-out files |
| Older repo storage | 10 GB for repos created before 2026-09-29 | Do not assume a newly created copy inherits this allowance |
| Account storage | 1 TB; increase available on request | Track aggregate retained repos |
| Repo and namespace counts | Unlimited in source table | Storage and rate limits still apply |
| Namespace name length | 2–63 characters | Validate before provisioning |
| Namespace/repo name characters | First letter/digit, then letters/digits/`.`/`_`/`-` | Use stable validated names |
| Push size | 64 MiB including all data in push | Split the history transfer into smaller pushes |
| Objects per push | 50,000 | Large histories can hit this before byte limit |
| File size | 32 MiB | Compressed files can fail slightly below the threshold |
| Ref updates per push | 1 MiB | Large branch/tag updates have their own limit |
| Entries per directory | 100,000 | Avoid excessively flat generated trees |

The source table gives a namespace length limit, not a separate repo-name length limit. Do not invent one. A repo below its total storage limit can still exceed a per-push or per-file limit. One oversized file cannot be fixed merely by sending fewer files in a push.

## Key Concepts
- **`artifactsEventsAdaptiveGroups`**: GraphQL Analytics dataset for Artifacts operations.
- **`accountTag`**: Required account filter.
- **`eventKind`**: `action` for successful operations, `error` for failures.
- **`eventType`**: Specific action/error, distinct from subscription event names.
- **GB-mo**: Billing storage unit based on average peak storage per day over a 30-day period.
- **Repository creation cohort**: Determines whether the documented 1 GB or older 10 GB repo limit applies.

## Metrics Technique
Metrics are queryable for the past **31 days**. Fields include `count`, `sum.durationMs`, `avg.durationMs`, and quantiles p25/p50/p75/p90/p95/p99/p999. Without filtering, count includes successful and failed events.

Group/filter by `repository` (`namespace/name`), `repositoryNamespace`, `repositoryName`, `eventKind`, `eventType`, `errorMessage`, and time dimensions from minutes through days.

| Analytics event type | Kind |
| --- | --- |
| `create`, `fork`, `push`, `pull`, `delete` | `action` |
| `storageLimitReached`, `serverError`, `clientError`, `rateLimited` | `error` |

Analytics `pull` includes fetch or clone. Do not filter this dataset using `cf.artifacts.repo.pushed`; that is a subscription event type from a different interface.

## Worked Example: Find Repositories with Errors
Adapted source query. Supply a real account ID and a time window within retention; use the GraphQL Analytics API's authentication and execution setup.

```graphql
query ArtifactsErrorsByRepo(
  $accountTag: String!
  $datetimeStart: Time
  $datetimeEnd: Time
) {
  viewer {
    accounts(filter: { accountTag: $accountTag }) {
      artifactsEventsAdaptiveGroups(
        limit: 100
        filter: {
          datetime_geq: $datetimeStart
          datetime_leq: $datetimeEnd
          eventKind: "error"
        }
        orderBy: [count_DESC]
      ) {
        count
        dimensions { repository eventType }
      }
    }
  }
}
```

1. Rank errors by repository and type.
2. For rate limits, identify whether namespace management traffic or one repo's Git traffic is hot.
3. For storage errors, inspect file, push, repository, and account constraints separately.
4. Compare latency within the same operation category; a mixed average can hide a slow tail.
5. Use application/Workflow logs for exact failed calls while keeping credentials out of logs.

The dataset name includes “Adaptive”; the source defines metric fields but does not justify extra claims about sampling accuracy or exact billing equivalence.

## Error Reference
| Name | Code | Handling direction |
| --- | --- | --- |
| `INVALID_INPUT` | 10100 | Correct missing/malformed/out-of-range input |
| `INVALID_REPO_NAME` | 10101 | Validate naming rules |
| `INVALID_TTL` | 10103 | Use 60–31,536,000 seconds |
| `INVALID_URL` | 10104 | Use a valid documented Git source |
| `REMOTE_AUTH_REQUIRED` | 10106 | Upstream auth required; do not assume private import support |
| `NOT_FOUND` | 10200 | Check identity/lifecycle |
| `ALREADY_EXISTS` | 10201 | Reconcile the collision |
| `IMPORT_IN_PROGRESS` | 10302 | Defer/retry follow-up access |
| `FORK_IN_PROGRESS` | 10303 | Defer/retry follow-up access |
| `INTERNAL_ERROR` | 10400 | Diagnose; bounded retry when appropriate |
| `UPSTREAM_UNAVAILABLE` | 10401 | Check upstream; bounded retry |
| `MEMORY_LIMIT` | 10402 | Reduce operation size or change approach |

This is the documented Artifacts application-error list, not a complete catalog of HTTP authentication or rate-limit statuses. Preserve both HTTP status and structured error details.

## Pricing Snapshot — Verify Before Quoting
Artifacts requires Workers Paid. The pricing page updated 2026-10-28 states billing starts **2026-11-12**. It supersedes an older changelog entry announcing 2026-10-14; this conflict should not be presented as two valid current start dates.

| Dimension | Included monthly | Additional rate |
| --- | --- | --- |
| Operations | 10,000 | $0.15 per 1,000 |
| Storage | 1 GB | $0.50 per GB-mo |

Storage aggregates repositories. Replicas do not add storage charges, and repositories remain stored until deletion. This table excludes the Workers Paid base charge and connected products such as Workflows, Containers, or R2. The source does not define every billing edge case, so do not infer rounding rules or free allowance pooling beyond the documented dimensions.

## Changelog Use
The changelog records open beta on 2026-10-01, new-repo storage limits on 2026-09-29, jurisdiction support on 2026-08-13, dashboard management on 2026-06-17, and Wrangler management on 2026-05-18. Older beta snippets use obsolete API routes and result shapes. Prefer current reference pages for code; use changelog entries for history and migration context.

## Anti-patterns
- **Deleting a large file only from the latest tree and assuming history shrank**: Git retains historical objects.
- **Sharding namespaces to fix one repo's Git limit**: The limits have different scopes.
- **Retrying invalid input**: Correct the request first.
- **Treating every 409 as safe to retry forever**: Inspect the cause and use a finite deadline.
- **Quoting snapshot prices as current**: Re-fetch pricing and limits first.

## Key Takeaways
1. Identify the scope and unit of the actual limit.
2. Monitor error kinds and tail latency by repo and operation.
3. Preserve specific error causes.
4. Review retention because repository data continues to consume storage.
5. Verify live prices, limits, and billing timing before estimating spend.

## Connects To
- [Chapter 1](ch01-foundations.md): Partitioning and retention.
- [Chapter 5](ch05-imports-and-forks.md): Readiness errors.
- [Chapter 7](ch07-build-and-deploy.md): Pipeline observability and additional product costs.

## Sources
- [Limits](https://developers.cloudflare.com/artifacts/platform/limits/)
- [Metrics](https://developers.cloudflare.com/artifacts/observability/metrics/)
- [Errors](https://developers.cloudflare.com/artifacts/api/errors/)
- [Pricing](https://developers.cloudflare.com/artifacts/platform/pricing/)
- [Changelog](https://developers.cloudflare.com/artifacts/platform/changelog/)

Snapshot: 2026-10-30. Diagnosis guidance is synthesized; dated rates and limits are not promises about future service behavior.
