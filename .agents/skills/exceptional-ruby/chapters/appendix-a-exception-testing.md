# Appendix A: Exception tester implementation

Source: printed pages 89–93; strategy context on pages 73–77.

## Core idea

Failure injection tests what remains true when execution stops between effects. The source's record/playback implementation is an experiment for discovering vulnerable call boundaries, not a complete verification system.

## The original technique

1. Run the operation with tracing enabled and record eligible method-call signatures.
2. Replay the operation, arranging for a chosen signature to raise a test exception.
3. Observe whether the operation propagates, handles, or obscures that failure.
4. Assert the chosen exception-safety guarantee after interruption.
5. Repeat across recorded locations with independently initialized state.

The source uses set_trace_func and a Set of signatures. The injected test exception descends directly from Exception to pass through ordinary StandardError handlers. That choice probes unwinding behavior; it does not mean application errors should generally inherit directly from Exception.

## Worked example: a swap interrupted between writes

A two-step mutation can leave a partial result even when the intended successful transformation is simple. The following reconstruction uses explicit checkpoints rather than a global trace hook. The checkpoints are a testing aid, not a proposed production API.

```ruby
def book_swap_in_place(pair, checkpoint)
  first = pair.fetch(0)
  pair[0] = pair.fetch(1)
  checkpoint.call(:after_first_write)
  pair[1] = first
  checkpoint.call(:after_second_write)
  pair
end

def book_swapped_copy(pair, checkpoint)
  copy = pair.dup
  first = copy.fetch(0)
  copy[0] = copy.fetch(1)
  checkpoint.call(:after_first_write)
  copy[1] = first
  checkpoint.call(:after_second_write)
  copy
end
```

For `[1, 2]`, an injected failure after the first in-place write leaves `[2, 2]`. That violates the strong guarantee because the input changed. Whether it also violates weak consistency depends on the declared invariant; if the pair must preserve its original members, it does.

The copy version leaves the original array unchanged at either checkpoint, and returns `[2, 1]` on success. This demonstrates a strong guarantee for the original array under the selected checkpoints. It does not prove atomicity for concurrent observers of an external assignment, shared nested objects, or arbitrary mutation inside a user-defined dup/fetch implementation. Use ordinary arrays of immutable values for this demonstration.

### Assertions that matter

For each injected point, create a fresh `[1, 2]`, save the starting value, invoke the operation, catch the intentional injected error, and compare the surviving state with the promised state. Test normal completion separately.

A useful test should deliberately expose the in-place failure, then confirm the copy's preservation. Merely asserting that both methods raise would miss the entire purpose.

## Limits of the historical harness

- A Set of call signatures collapses repeated occurrences; it does not explore every individual call in a loop.
- The recording implementation needs careful cleanup if the operation itself raises. Always remove instrumentation in ensure; leaving global tracing active contaminates later work.
- Global tracing interacts with unrelated threads and code. The prototype is not an isolated concurrency test.
- A replay may take a different path after failure. Observed call points from a successful run are not exhaustive coverage.
- Injecting at calls does not model every possible interruption, process kill, native extension event, or external side effect.
- Reusing mutated fixtures between replays invalidates comparisons. Initialize state and resource doubles afresh.
- A test exception that bypasses StandardError handlers tests a different failure model from a real IOError caught by application policy. Exercise relevant real classes separately.

**Adaptation:** a modern implementation could use scoped TracePoint instrumentation or explicit fault seams, but no replacement tracer is bundled. The smallest useful application is a targeted test at a critical state transition.

## Applying exception safety tests

Start with the guarantee, not with instrumentation. For weak safety, assert invariants and owned-resource release. For strong safety, assert unchanged observable state or reliable rollback. For a scoped nothrow promise, assert that represented failures yield a documented unsuccessful result and still preserve state.

List external effects separately. An in-memory test cannot prove that a remote server rolled back a request after a network failure. Use the application-specific transaction, compensation, or idempotency evidence needed for that promise.

## Takeaways

Inject failure where partial work becomes visible. Compare state after failure. Keep each replay independent and instrumentation temporary. Interpret passing tests only within the failure points and runtime actually exercised.

See [Exception Safety](ch06-failure-handling-strategy.md) for the guarantee definitions and [lifecycle](ch03-exception-lifecycle.md) for unwinding and ensure.
