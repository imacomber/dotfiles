# The life-cycle of an exception

Source: printed pages 18–48. Contents: raising and unwinding; ensure; rescue; retry; failures during handling; else; uncaught errors; threads; performance.

## Core idea

An exception moves through a specific sequence: creation or selection, backtrace assignment, active-exception state, stack unwinding, handler selection, and possible propagation. Small changes to rescue scope or cleanup can change the result of the entire operation.

## Raising and unwinding

`raise` and `fail` are synonymous Kernel methods, not keywords. The source cites the convention of using fail for a new failure and raise for propagation; it is an optional style, not a semantic distinction.

Common forms:

| Form | Purpose |
|---|---|
| `raise "message"` | Create a RuntimeError |
| `raise ErrorClass, "message"` | Create an instance through the exception protocol |
| `raise error` | Raise an existing exception object |
| `raise` | Re-raise the active exception; with none, raise a RuntimeError |
| `raise ErrorClass, "message", backtrace` | Supply explicit backtrace information |

Ruby obtains the exception via `#exception`; a class normally constructs an instance, while an instance normally returns itself when no replacement message is requested. Custom exception-protocol objects are possible, but make a public API harder to understand unless they solve a real problem. `Exception#exception` with a new message may create a different object; do not rely on identity after rewriting it.

The backtrace records where the failure arose. Setting or replacing it is diagnostic surgery: avoid erasing the original location merely to make a wrapper look local. `caller` can obtain calling context; capture only what the diagnostic needs.

`$!` is the currently handled exception, also accessible through `$ERROR_INFO` after requiring English. It is contextual state, not an application-wide error registry. Prefer a named rescue variable for code that should be easy to follow. A nested handler temporarily changes the active exception; after it completes, the outer rescue still has its own bound error.

Unwinding abandons normal execution toward a matching handler, executing intervening ensure clauses. The call stack is not rolled back: mutations and external effects already performed remain unless the program explicitly compensates for them.

### Overriding raise

The source demonstrates replacing raise for immediate termination and interactive debugging, including historical Hammertime integration. Treat these as demonstrations of Ruby's method dispatch. Global overrides affect libraries and can disable normal rescue, cleanup, and diagnostics. Do not install those old hooks as a default strategy; use the runtime's debugging facilities and narrow instrumentation when appropriate.

## ensure

Use ensure for obligations such as releasing an acquired resource on both success and ordinary exception unwinding.

```ruby
def book_with_resource(resource)
  yield resource
ensure
  resource.close
end
```

The yielded value remains the method's result when cleanup succeeds. A failure from the block propagates after cleanup. A failure from close can become the escaping failure, so the snippet assumes close succeeds or that its failure is intentionally primary. If acquisition occurs inside the protected region, make cleanup conditional on actually owning a resource.

An explicit return from ensure can replace a pending result and suppress a pending exception. Avoid it. Cleanup expressions do not need an explicit return. Also avoid accidentally raising an unrelated exception while assembling diagnostics or releasing the first of several resources; later obligations may then be skipped. Nested ensure clauses can preserve multiple cleanup obligations, but the application still needs a policy for multiple failures.

Ensure is not a guarantee against an immediate process exit, kill, machine crash, or every asynchronous interruption. The state guarantee must match the actual environment.

## Coming to the rescue

A bare rescue selects StandardError descendants. `rescue Exception` also intercepts categories normally allowed to terminate or interrupt work, including SystemExit and Interrupt. Use the smallest appropriate failure family and scope.

Handlers are considered in order; put a more specific class before its superclass. Multiple classes can share a handler. A splatted array can choose classes dynamically, but the reader must still understand the resulting boundary. Avoid computing a broad recovery policy from arbitrary untrusted data.

The source explores custom matcher modules/classes using `===` to select errors by other criteria. Rescue targets must still be acceptable class/module matchers. Message-based matching is brittle because wording changes and messages can contain variable data. Prefer a meaningful exception class or structured attributes where you control the API.

A modifier such as `read_value rescue nil` catches StandardError failures from that expression. It does not mean “only return nil when this particular known problem occurs.” It can also erase a bug inside read_value. A short method with a narrow rescue is usually easier to audit.

### Scope matters more than indentation aesthetics

A rescue around “read, transform, notify” may catch failures from all three operations. If only reading is recoverable, isolate that operation. A client callback belongs outside a library's rescue when the library must not reinterpret client bugs as its own failure. Method-level rescue is useful when the entire method is genuinely the protected operation; it is misleading when the method also contains unrelated success work.

## retry

Retry re-enters the protected body, not merely the statement that failed. Initialize counters outside it and include a stopping rule.

```ruby
def book_retry_io(max_attempts: 3)
  unless max_attempts.is_a?(Integer) && max_attempts > 0
    fail ArgumentError, "max_attempts must be a positive integer"
  end

  attempts = 0
  begin
    attempts += 1
    yield attempts
  rescue IOError
    retry if attempts < max_attempts
    raise
  end
end
```

The total attempt count is at most max_attempts, including the first attempt. Other StandardError types propagate immediately. The last IOError is re-raised with its identity and diagnostic origin intact.

**Adaptation:** the block is an explicitly retryable operation. Before using this around real work, decide which effects can repeat, how partially completed state resets, and what deadline/backoff applies. Retrying a charge after losing the response may duplicate an effect that already succeeded remotely. Sleeping in a request is not automatically the right scheduling policy. The book's mechanics do not supply a production retry design.

## raise during exception handling

A handler can fail while it tries to explain or recover from the original error. Keep diagnostic construction simple, preserve the original exception, and avoid assuming the reporting channel is reliable.

Use bare raise to re-raise the active error. Creating a new generic error with the same message changes class, identity, and usually backtrace. If an abstraction boundary calls for translation, use a meaningful domain error and preserve the cause.

```ruby
module BookInput
  class ReadError < StandardError; end

  def self.read_from(reader)
    reader.read
  rescue IOError => error
    fail ReadError, "input could not be read", cause: error
  end
end
```

Only the reader operation is protected. ArgumentError or a programming defect is not silently recategorized. Callers can handle ReadError and inspect its cause for the underlying IO failure.

**Version correction:** the source builds a nested-exception facility because its Ruby did not provide one. Ruby 3.4 already records the active exception as the default cause; an explicit cause can select an exception or nil. Prefer the built-in mechanism rather than copying the source's global patch. See [Kernel raise](https://docs.ruby-lang.org/en/3.4/Kernel.html#method-i-raise) and [Exception cause](https://docs.ruby-lang.org/en/3.4/Exception.html#method-i-cause).

The source also explores disallowing a second failure inside rescue. That can surface masking bugs during development, but indiscriminately forbidding nested failures prevents legitimate error translation and can itself replace diagnostics. Treat it as a debugging experiment, not a required runtime rule.

## else

Else runs only when the protected body completes without an exception. Exceptions raised in else are not handled by the rescue clauses immediately before it.

```ruby
def book_read_and_notify(reader, on_success)
  value = reader.read
rescue IOError => error
  [:read_failed, error]
else
  on_success.call(value)
  value
end
```

A read IOError produces an explicit failed result. An IOError from on_success propagates. Without this separation, a callback failure could be mislabeled as “read failed” even after reading succeeded. Ensure, if present, still surrounds the construct's completion paths.

Why it works: syntax expresses the boundary between recovering from an operation and responding to its success. The policy is visible without introducing an extra class.

## Uncaught exceptions

An exception that finds no matching handler reaches the surrounding runtime boundary. A command-line program commonly prints diagnostics and exits unsuccessfully; a framework may own a request/job handler instead. Know which boundary applies before claiming an exception necessarily terminates the whole application.

The source discusses top-level handling and at_exit hooks. An at_exit hook can inspect the active exception, but a SystemExit is also an exception and does not automatically represent a crash. Hooks can fail too and alter shutdown behavior. Keep them small and test termination behavior in a child process.

Do not swallow an uncaught failure merely to produce a successful exit status. If output formatting is customized, preserve the failure status and enough original evidence to investigate it.

## Exceptions in threads

A worker thread's failure is not equivalent to a successful worker result. Joining a failed thread or reading its value raises the stored failure. Design who joins workers, observes completion, and decides whether other work must stop.

**Version correction:** modern Ruby reports unhandled thread exceptions to stderr by default (`report_on_exception` has defaulted to true since 2.5). Reporting is distinct from propagating the error to the main thread through abort_on_exception or retrieving it through join/value. See [Ruby 3.4 Thread](https://docs.ruby-lang.org/en/3.4/Thread.html). Do not reproduce the source-era assumption that an unobserved worker necessarily fails silently.

Avoid setting process-wide thread reporting options in a library just to change its own worker policy. Configure or observe the owned thread.

## Are Ruby exceptions slow?

The source benchmarks rescue, raise, and alternative control flow on its contemporary runtimes. Those numbers are historical and do not establish a modern universal threshold. Distinguish the cost of a protected region from actually creating, raising, and unwinding an exception.

Use ordinary values or flow constructs for expected high-frequency outcomes when that represents the contract clearly. If exception cost matters in a real workload, measure the actual runtime and path. Do not make a fragile API solely to optimize an old microbenchmark.

## Anti-patterns and review checks

- Ensure returns or cleanup failures erase a useful primary failure.
- A broad rescue misclassifies client callbacks, validation, and dependency failure alike.
- Retry resets its counter or repeats non-idempotent work indefinitely.
- A wrapper keeps only error.message and destroys diagnostic structure.
- A thread is launched without a plan for observing its failure.
- An old debugging monkey patch becomes a production default.

Connect to [response policies](ch04-responding-to-failures.md), [API strategy](ch06-failure-handling-strategy.md), and [standard exception families](appendix-b-standard-exceptions.md).
