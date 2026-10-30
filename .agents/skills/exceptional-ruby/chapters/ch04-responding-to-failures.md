# Responding to failures

Source: printed pages 49–55.

## Core idea

A response must fit both the importance of the failed operation and the reliability of the response mechanism. Converting a failure to nil, printing a warning, sending an alert, retrying, and terminating all create different contracts.

## Failure flags and benign values

A flag communicates success or failure; a benign value lets the caller keep working in a meaningful way. They are related but not interchangeable. Returning an empty list after a failed optional recommendation lookup may be acceptable. Returning an empty list after a failed authoritative inventory read can falsely assert that nothing is in stock.

Before selecting a fallback:

1. Define what the returned value means to the caller.
2. Check whether it is indistinguishable from a valid result.
3. Decide whether the caller needs the original error or a separate status.
4. Verify that degraded operation is actually permitted.

A nil result is useful when absence is a supported answer. It is damaging when callers interpret it as successful completion or when the lost diagnostic was the only evidence of a required operation failing.

## Reporting failure to the console

Use a diagnostic channel appropriate to the program. The source contrasts ordinary output, warnings, and failure signaling. `warn` writes to stderr; a message by itself neither repairs the operation nor establishes the intended exit status.

Warnings can reveal suspicious conditions without immediately stopping execution. During development, the source considers turning warnings into errors to expose neglected cases. That is a diagnostic policy, not a blanket requirement to monkey-patch warn in every program. Libraries should not casually redefine global reporting behavior.

Make messages actionable: name the failed operation and useful context. Avoid dumping arbitrary objects or credentials. Keep machine-readable success output separate from diagnostics where callers rely on it.

## Remote failure reporting

Remote reporting adds another dependency to an already failing path. In the source's cascading-failure example, a shared mail account becomes throttled; reporting the first failures then fails too, spreading damage to other workers and users sharing the account.

Model reporting as fallible work. Consider destination unavailability, timeouts, rate limits, malformed context, and exceptions from the reporter itself. A handler that merely calls another network dependency is not a containment boundary.

### Bulkheads

A bulkhead contains a failure within a bounded subsystem so unrelated work can continue. Identify the boundary, failure family, fallback channel, and what must still propagate.

**Reconstruction:** reporting an already-known error through an IO-based reporter. The fallback receives both errors rather than replacing the original evidence.

```ruby
def book_report_failure(original_error, reporter, fallback)
  reporter.call(original_error)
rescue IOError => reporting_error
  fallback.call(original_error, reporting_error)
  nil
end
```

This snippet contains known IO failures from the reporter. It does not promise that fallback cannot fail; a fallback failure propagates. A real dependable fallback should use a simpler channel and have a deliberately bounded failure policy. Neither this helper nor a successful report changes whether the original operation succeeded.

**Adaptation:** the source's illustrative catch-all uses Exception. Do not carry that scope into application code without deciding how interrupts, process shutdown, and resource exhaustion must behave. Prefer explicit expected reporter failures, or a carefully scoped StandardError boundary when that matches the reporter contract. No handler can promise survival against every process-level event.

### The Circuit Breaker pattern

Use a circuit breaker when repeated attempts against a failing dependency waste capacity or amplify an outage. A bulkhead limits the reach of failure; a circuit breaker limits future attempts. They address different parts of the cascade.

| State | Action | Transition |
|---|---|---|
| Closed | Permit calls; observe relevant failures | Open after the chosen failure condition |
| Open | Skip the dependency; fail fast or provide documented degradation | Allow a probe after a deliberate reset condition |
| Half-open | Permit a limited probe | Success closes; failure reopens |

Decide which failures count, when counts reset, how callers see an open circuit, and how concurrent probes are controlled. The book supplies the pattern, not universal retry counts or timeout values. A fallback that repeatedly calls another saturated dependency simply moves the failure elsewhere.

## Ending the program

Sometimes continuing cannot fulfill a useful contract. End deliberately and preserve the failure status.

| Facility | Intended role | Cleanup implications |
|---|---|---|
| Unhandled exception | Propagate a failure to the owning runtime boundary | Normal unwinding applies until that boundary |
| `abort` | Emit an error and terminate unsuccessfully | Uses normal SystemExit behavior |
| `exit` | Request termination with a selected status | Raises SystemExit; ensure/exit hooks can run |
| `exit!` | Immediate process termination | Bypasses normal cleanup and exit hooks |

Keep termination policy in the executable or other owning boundary. A reusable library should normally give its caller a chance to recover. Do not run termination examples in the agent's own process; use a child process to inspect status and output.

The source explores the interaction between exit status, rescue, and shutdown hooks. A broad Exception handler can intercept SystemExit, so “calling exit always stops this code immediately” is an unsafe assumption. Conversely, exit! is inappropriate for ordinary cleanup-dependent shutdown.

## Worked policy review

Suppose a background operation commits a required update, then sends a nonessential alert. If the alert fails, report degraded notification without pretending the update failed and blindly retrying it. If the update fails before commit, an alert cannot turn that failure into success. If alert reporting also fails, contain that secondary failure at a separately defined boundary while retaining the original error.

**Adaptation:** idempotency and durable transaction details belong to the application. The book supplies the failure-policy questions; a local rescue cannot establish remote or database atomicity.

## Takeaways

A benign result must be truthful. A reporter needs its own failure policy. A bulkhead contains damage, a circuit breaker reduces repeated exposure, and termination belongs to a boundary that owns the program's outcome.

Continue with [alternative signals](ch05-alternatives-to-exceptions.md) or [exception safety](ch06-failure-handling-strategy.md).
