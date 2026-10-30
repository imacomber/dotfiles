# Alternatives to exceptions

Source: printed pages 56–63.

## Core idea

Choose the shape of the failure signal for the caller's decision. An exception is useful for abandoning a failed operation across intervening calls; ordinary results, caller policies, and process objects can express expected outcomes more directly.

## Sideband data

Sideband information travels alongside the principal result. It can retain warnings or partial diagnostics without making those problems the control-flow mechanism. Keep its meaning explicit: a result accompanied by problems must say whether it is complete, partial, or unusable.

Do not use sideband status as an excuse to ignore required failure. Callers must know what to inspect before trusting the result.

## Returning multiple values

A value/status tuple is compact and works well at a small boundary. Define order and meaning, including the distinction between a valid nil value and failure. Positional tuples become harder to read as more fields accumulate; at that point, a named result or domain process object may be clearer.

Avoid two contradictory authorities, such as success=true alongside a fatal problem. Choose one success rule and derive other observations from it.

## Output parameters and transcripts

A caller-owned collection can accumulate problems through several calls. The source's transcript idea provides a place for messages from a larger operation rather than throwing away useful work at the first failure.

Trade-offs:

- It preserves several observations and can keep a partial result inspectable.
- It requires the caller to supply and inspect the collection consistently.
- Hidden mutation makes ownership less obvious than returning a value.
- Passing the transcript through every layer can spread failure-reporting plumbing.

Prefer structured problem data when code must act on the result; human-readable prose alone makes later branching fragile. Do not collect an error and then present the overall operation as complete without a defined rule.

## Caller-supplied fallback strategy

A caller often knows whether absence should produce a default, an alternative lookup, or an exception. Let it supply that policy rather than guessing inside the lower-level method. Standard examples include Hash#fetch and Enumerable#detect/find with a fallback.

```ruby
def book_fetch_setting(settings, key, &fallback)
  return settings.fetch(key) unless fallback

  settings.fetch(key, &fallback)
end
```

A present false or nil remains a present value. With no fallback, a missing key raises KeyError. With a fallback, the caller decides the missing-key outcome. If the fallback raises, that error propagates; it is client code, not automatically a storage failure.

The source also uses callable default policies, including a raising policy. A block or callable can make expected failure flexible without adding a class hierarchy. Do not add several competing fallback mechanisms to a small API when one is sufficient.

## Global variables and ambient error state

An ambient “last error” avoids passing an explicit result, but introduces implicit communication. Another call can overwrite it; reentrant or concurrent work can confuse ownership; a successful call may leave stale failure state unless resetting is defined.

Use an explicit return value or process object where practical. If ambient state is unavoidable, define scope, initialization, reset, and nesting behavior. Restore previous state in ensure rather than merely setting nil if nested callers must retain an outer context.

**Version note:** Ruby's `Thread.current[:key]` storage is fiber-local, despite the thread receiver. Actual thread variables use thread_variable_get/set. A historical thread-local recipe therefore needs review in fiber-based execution. See [Ruby 3.4 Thread](https://docs.ruby-lang.org/en/3.4/Thread.html). This distinction is a reason to prefer explicit state, not a reason to replace all fiber-local storage indiscriminately.

## Process reification

Turn a complex operation into an object when its results, progress, and problems deserve a shared lifetime. Callers can inspect the process instead of reconstructing state from several side channels. This adds a real abstraction cost; a one-step lookup usually needs only a value or caller fallback.

**Reconstruction:** collect known failures from independent checks. A failed check is skipped, and successful values remain available. Unexpected bugs still propagate.

```ruby
class BookCheckRun
  class Unavailable < StandardError; end

  attr_reader :values, :problems

  def initialize
    @values = []
    @problems = []
  end

  def check
    value = yield
  rescue Unavailable => error
    @problems << error
    nil
  else
    @values << value
    value
  end

  def complete?
    @problems.empty?
  end
end
```

The caller owns the sequence and must inspect complete? before presenting a complete answer. This reconstruction is suitable only when checks are independent and partial output is useful. It is not a general transaction coordinator, an automatic retry engine, or a promise to swallow arbitrary callback failures. The block is the explicit check boundary and raises the dedicated known failure type to opt into collection.

Why it works: the operation object gives results and diagnostics a visible owner. Why it can fail: users may treat values as complete while ignoring problems, or reuse one run across unrelated operations and accumulate stale state. Create a fresh object for each logical run.

## Beyond exceptions

The source discusses Cond and restart-oriented conditions as an experimental alternative: signaling a problem can be separated from choosing a recovery that resumes computation. Treat the gem and its APIs as historical examples, not an instruction to install it or a guarantee of present support.

For ordinary code, first decide whether a simple block, return value, or domain object already expresses the needed recovery. A more powerful condition system is not automatically a clearer contract.

## Selection table

| Need | Candidate | Main cost |
|---|---|---|
| One expected negative answer | Documented value/flag | Ambiguity if valid values overlap |
| Small result plus status | Tuple | Positional coupling |
| Several observations through steps | Transcript/output collection | Shared mutation and plumbing |
| Caller-specific missing-result policy | Block/callable fallback | Callback ownership must stay clear |
| Substantial operation with partial state | Process object | Extra lifecycle and abstraction |
| Abandon a failed contract across layers | Exception | Unwinding and state-safety obligations |

## Anti-patterns and takeaways

Do not replace exceptions with a status callers are unlikely to check. Avoid ambient mutable error state when explicit data is cheap. Keep client policy separate from low-level recovery. Use process reification when it earns its place through real state and diagnostics.

See [strategy](ch06-failure-handling-strategy.md) for expected control flow, no-raise APIs, and the five questions before raising.
