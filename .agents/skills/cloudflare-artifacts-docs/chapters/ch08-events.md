# Chapter 8: Event-driven automation

## Core Idea
React to repository lifecycle and Git activity through structured Artifacts events. Choose account or repository scope deliberately, and use the pushed ref and commit identity when starting work.

## Key Concepts
- **Account-level source `artifacts`**: Lifecycle events across repositories in the account.
- **Repository-level source `artifacts.repo`**: Git and token activity for a selected namespace and repo.
- **Event type**: Fully qualified name such as `cf.artifacts.repo.pushed`.
- **Source identity**: Event `source.namespace` and `source.repoName`.
- **Subscription filter**: Configuration uses `repo_name`, while payload source identity uses `repoName`.
- **Schema version**: `metadata.eventSchemaVersion`, available to guide payload parsing.
- **Push boundaries**: `before`, `after`, and `ref` identify the affected Git ref and change.

## Event Reference
| Event suffix after `cf.artifacts.repo.` | Subscription source | Payload highlights |
| --- | --- | --- |
| `created` | `artifacts` | Repo ID, default branch, description, timestamps, read-only state |
| `deleted` | `artifacts` | Deleted repository metadata |
| `forked` | `artifacts` | Target namespace, repo name, ID and metadata; source identifies the original repo |
| `imported` | `artifacts` | Repo metadata, source URL, branch |
| `pushed` | `artifacts.repo` | Ref, before/after hashes, commits, total count, truncation flags |
| `cloned` | `artifacts.repo` | Empty payload in the source example |
| `fetched` | `artifacts.repo` | Empty payload in the source example |
| `token.created` | `artifacts.repo` | Token ID |
| `token.revoked` | `artifacts.repo` | Token ID |

Do not assume every event has the same payload. A fork's source and destination are different identities. Token events report IDs; the examples do not supply plaintext credentials.

## Envelope Shape
Reconstructed push example with abbreviated content:

```json
{
  "type": "cf.artifacts.repo.pushed",
  "source": {
    "type": "artifacts.repo",
    "namespace": "staging",
    "repoName": "session-42"
  },
  "payload": {
    "ref": "refs/heads/main",
    "before": "1111111111111111111111111111111111111111",
    "after": "2222222222222222222222222222222222222222",
    "commits": [],
    "totalCommitsCount": 2,
    "commitsTruncated": true
  },
  "metadata": {
    "accountId": "example-account",
    "eventSubscriptionId": "example-subscription",
    "eventSchemaVersion": 1,
    "eventTimestamp": "2026-10-30T12:00:00Z"
  }
}
```

The placeholder hashes are illustrative, not repository objects. A commit entry can contain `id`, `message`, `messageTruncated`, `timestamp`, author, committer, and parents. When `commitsTruncated` or `messageTruncated` is true, retrieve the details needed from the repository instead of treating the included data as complete.

## Subscription Technique
The guide routes subscriptions through Cloudflare's event subscriptions system, linked to Queues. For a custom build, the deployment guide also documents a Wrangler event trigger targeting a Workflow:

```json
{
  "triggers": {
    "events": [{
      "type": "cf.artifacts.repo.pushed",
      "filter": { "namespace": "staging", "repo_name": "session-42" },
      "targets": [{ "type": "workflow", "workflow_name": "review-workflow" }]
    }]
  }
}
```

This fragment requires an existing matching Workflow definition and surrounding bindings. Use current event-subscription/Queues documentation for general queue provisioning and consumer setup; the Artifacts event page alone does not specify that complete setup.

## Worked Example: Review the Pushed Commit
1. Subscribe to pushes for the intended repository or workload namespace.
2. Validate the event shape and supported schema version at the handler boundary.
3. Resolve the authorized repository using namespace and `repoName`.
4. Match `payload.ref` to the refs the automation is intended to review.
5. Use `payload.after` as the target commit rather than reading whichever commit the branch points to later.
6. Obtain a read token and fetch the needed content.
7. If commit details are truncated, retrieve history or commit objects explicitly.
8. Store the review result against the repository, ref, and target commit.

Using an immutable commit avoids a later push moving the branch while a review starts. That is an inference from Git semantics. The Artifacts event page does not document ordering, delivery guarantees, a unique delivery ID, or a deduplication contract. If the actual delivery mechanism can retry, make the consumer idempotent using a key appropriate to its effect; do not call `eventSubscriptionId` a unique event ID, because it identifies a subscription.

## Anti-patterns
- **Short type `pushed` in a Wrangler trigger**: The documented full name is `cf.artifacts.repo.pushed`.
- **Using config `repo_name` to read event source identity**: The payload uses `repoName`.
- **Reviewing the latest branch head after a delayed event**: It may differ from the pushed target.
- **Assuming the commit array is complete**: Check truncation flags.
- **Treating fork source as destination**: Read the new repo identity from the fork payload.
- **Assuming exactly-once, ordered delivery**: Not specified by the Artifacts event source page.

## Key Takeaways
1. Match event source scope to the automation boundary.
2. Parse each event type's actual payload.
3. Bind work to the event's ref and commit identity.
4. Respect truncation and schema metadata.
5. Verify delivery guarantees in the chosen target system.

## Connects To
- [Chapter 7](ch07-build-and-deploy.md): Push-triggered CI.
- [Chapter 2](ch02-workers.md): Commit and file inspection.
- [Chapter 4](ch04-authentication-and-git.md): Read-only credentials for review.

## Sources
- [Event subscriptions](https://developers.cloudflare.com/artifacts/guides/event-subscriptions/)
- [Build/deploy trigger configuration](https://developers.cloudflare.com/artifacts/guides/build-and-deploy-on-push/)
- [General event subscriptions, linked follow-up](https://developers.cloudflare.com/queues/event-subscriptions/)

Snapshot: 2026-10-30. Consumer validation, commit pinning, and idempotency guidance are implementation inferences; the linked general subscription documentation was not part of the extracted corpus.
