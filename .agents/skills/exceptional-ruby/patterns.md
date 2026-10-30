# Pattern catalog

These are decision-ready techniques, not mandatory abstractions. References link to fuller reasoning and reconstructed examples.

## Contract-first failure design
**When to use:** The right signal or recovery owner is unclear.
**How:** Identify preconditions, promised effects, and invariant; classify the broken promise; select the caller response.
**Trade-offs:** Requires domain meaning; an exception class alone cannot decide policy. [ch02](chapters/ch02-what-is-a-failure.md)

## Specific rescue boundary
**When to use:** One operation has a known recovery.
**How:** Protect only that operation, match its intended classes, and leave unrelated callbacks outside.
**Trade-offs:** Narrow types still catch too much if scope includes unrelated work. [ch03](chapters/ch03-exception-lifecycle.md)

## Success-only else
**When to use:** Success callbacks or logging must not be mistaken for primary-operation failure.
**How:** Put the operation in the protected body and success work in else.
**Trade-offs:** Success-work errors propagate and still need an appropriate owning boundary. [ch03](chapters/ch03-exception-lifecycle.md)

## Ensure-owned cleanup
**When to use:** A resource must be released on normal return and unwinding.
**How:** Track ownership, clean up in ensure, and avoid explicit return there.
**Trade-offs:** Cleanup may fail or mask the original; immediate process death bypasses ordinary guarantees. [ch03](chapters/ch03-exception-lifecycle.md)

## Diagnostic propagation and translation
**When to use:** A failure crosses an abstraction boundary.
**How:** Bare raise preserves the active error; translate only for useful domain meaning and preserve its cause/context.
**Trade-offs:** Wrapping changes rescue matching; copying only a message erases evidence. Built-in cause is a modern correction. [ch03](chapters/ch03-exception-lifecycle.md)

## Bounded retry
**When to use:** A specifically identified failure may resolve on another attempt.
**How:** Count attempts outside the retried body; stop at a defined bound; propagate the last error.
**Trade-offs:** Repeats all protected effects. Idempotency, timing, and deadlines need application policy. [ch03](chapters/ch03-exception-lifecycle.md)

## Benign fallback
**When to use:** Degraded operation is explicitly acceptable.
**How:** Return a value that truthfully represents the permitted degraded result; retain separate failure status if needed.
**Trade-offs:** A valid-looking empty result can conceal lost required work. [ch04](chapters/ch04-responding-to-failures.md)

## Reporting bulkhead
**When to use:** An error reporter can spread failure into unrelated work.
**How:** Bound the reporter operation, contain its declared failures, and retain original plus reporting diagnostics in a simpler fallback.
**Trade-offs:** Fallback can also fail; broad catch-all handling can interfere with shutdown. [ch04](chapters/ch04-responding-to-failures.md)

## Circuit Breaker
**When to use:** Repeated calls to a failing dependency amplify an outage.
**How:** Closed permits calls, open skips them, half-open probes recovery; define relevant failure counts and reset policy.
**Trade-offs:** Thresholds, concurrency, and fallback are workload-specific; it does not undo effects. [ch04](chapters/ch04-responding-to-failures.md)

## Sideband result / multiple values
**When to use:** A small operation returns useful data and a status/problem.
**How:** Define the tuple or result contract and one clear completion rule.
**Trade-offs:** Positional coupling and unchecked status can hide failure. [ch05](chapters/ch05-alternatives-to-exceptions.md)

## Transcript / output collection
**When to use:** Several steps produce useful observations despite selected failures.
**How:** Give a caller-owned collection explicit lifetime and inspection rules.
**Trade-offs:** Shared mutation and plumbing; a transcript alone does not establish successful completion. [ch05](chapters/ch05-alternatives-to-exceptions.md)

## Caller-supplied fallback strategy
**When to use:** The caller knows whether absence merits a default, alternative, or error.
**How:** Accept a block/callable; preserve nil/false as present values; propagate callback defects.
**Trade-offs:** Too many policy knobs obscure a small API. [ch05](chapters/ch05-alternatives-to-exceptions.md)

## Process reification
**When to use:** A substantial operation needs a shared home for partial output, progress, and problems.
**How:** Use a domain object with explicit completion/inspection behavior and a fresh lifetime per run.
**Trade-offs:** Extra abstraction; clients must still inspect problems. [ch05](chapters/ch05-alternatives-to-exceptions.md)

## Expected nonlocal completion
**When to use:** A normal early answer must cross intervening calls.
**How:** Use catch/throw with visible tag ownership; prefer return/break where sufficient.
**Trade-offs:** Distant control transfer can surprise readers; it is unrelated to rescue. [ch06](chapters/ch06-failure-handling-strategy.md)

## Contingency Method
**When to use:** A specific recovery policy recurs or clutters the normal path.
**How:** Extract the operation and narrow handler into a well-named method.
**Trade-offs:** A generic swallow-errors wrapper erases the contract. [ch06](chapters/ch06-failure-handling-strategy.md)

## Exception-safety guarantee
**When to use:** Partial mutation or resource ownership matters.
**How:** Choose weak, strong, or scoped nothrow; prepare state before commit or provide reliable rollback; test the promise.
**Trade-offs:** Strong safety can require copying/transactions; external effects need separate reasoning. [ch06](chapters/ch06-failure-handling-strategy.md)

## Record/playback failure injection
**When to use:** A critical state transition has an unproven failure guarantee.
**How:** Inject at selected call boundaries; reset fixtures for every run; compare surviving state and resources.
**Trade-offs:** The historical tracing prototype misses paths/repeated occurrences and needs instrumentation cleanup. [appA](chapters/appendix-a-exception-testing.md)

## Namespaced exception family
**When to use:** Callers need a stable way to rescue a library's declared failures.
**How:** Choose a base below StandardError and subclasses that imply different caller actions.
**Trade-offs:** Translating external exceptions changes concrete-class matching. [ch06](chapters/ch06-failure-handling-strategy.md)

## Module-tagged exception
**When to use:** Both original concrete type and library category must remain rescuable.
**How:** Extend an owned exception with a category module and re-raise it.
**Trade-offs:** Mutates the error; frozen exceptions reject extension; often a normal domain class is simpler. [ch06](chapters/ch06-failure-handling-strategy.md)

## No-raise API
**When to use:** Declared failures should remain inspectable without unwinding.
**How:** Return explicit status/results or a process object, defining completion and diagnostic access.
**Trade-offs:** Universal no-escape claims are unrealistic; do not silently absorb client bugs. [ch06](chapters/ch06-failure-handling-strategy.md)

## Response-oriented error taxonomy
**When to use:** Internal exception names fail to help callers act.
**How:** Distinguish correctable User Error, reportable Logic Error, and potentially recoverable Transient Failure; optionally separate InternalError/ClientError.
**Trade-offs:** Conceptual categories need not become a hierarchy in every small program. [ch06](chapters/ch06-failure-handling-strategy.md)
