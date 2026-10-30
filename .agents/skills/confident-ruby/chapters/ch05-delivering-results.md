# Chapter 5: Delivering Results

**Source:** printed pp. 213-249; sections 5.1-5.7.

## Core idea

An output contract should let calling code be as confident as the implementation. Choose a result shape or interaction that communicates meaning without forcing every caller to rediscover nil cases, result types, or undocumented outcome flags.

## 5.1 Write total functions

**When:** a query may find zero, one, or many meaningful results.

**How:** consistently return a collection, including from guard clauses and special paths. Let `select` return its array rather than converting its zero and singleton cases to nil and a scalar. If an unavoidable source has mixed shapes, normalize at its boundary rather than teaching every caller to branch.

**Why it works:** mapping, iterating, and concatenating work uniformly. Empty collections often express absence without an additional control-flow construct.

**Terminology:** mathematical totality means defined for every member of the input domain. The book deliberately uses a narrower programming convention: avoid nil and preserve a collection shape when collection results are possible. A method can satisfy this convention and still raise on invalid input or operational failure.

**Failure modes:** an early bare return reintroduces nil; a special magic-value branch reintroduces a scalar. Returning an empty array after a real failure can erase the distinction between no matches and a failed search.

## 5.2 Call back instead of returning

**When:** a command makes a change, and the caller should act only when that change occurs.

**How:** invoke a supplied callback after the successful change, passing useful context. For a no-change outcome, do not invoke it. Give the captured block a meaningful name when its purpose would otherwise be unclear.

The source import example should notify a purchaser only for a new imported purchase. A true/false result makes the caller interpret a cryptic condition; a callback states what to do when an import happens. The same interface can later invoke the block once for each successful record in a batch.

**Command-query separation:** commands change state; queries return information. Callback-based commands can express event consequences without overloading a boolean return. This is a design preference, not a ban on useful return values.

**Adaptation:** invoking a callback does not provide exactly-once delivery. Production imports still need appropriate duplicate prevention, transaction boundaries, and failure/retry handling. Do not claim idempotency from a callback API alone.

## 5.3 Represent failure with a benign value

**When:** a returned value is useful but nonessential, and an empty or otherwise harmless value fits the caller's ordinary operations.

**How:** return a suitable value in the expected role, such as an empty string for optional markup, rather than nil that would break concatenation.

The source's optional social-feed sidebar returns an empty string when fetching fails. That lets page construction continue. The same decision would be dishonest if the caller needed proof of successful delivery or an authoritative record of absence.

**Trade-off:** simplicity costs information. An empty string alone cannot distinguish an unavailable service from a legitimate empty result. Keep a richer contract if that distinction matters; do not suggest `empty?` proves a particular failure occurred.

## 5.4 Represent failure with a special case object

**When:** a query's missing result corresponds to a coherent alternate domain role.

**How:** return the role's special implementation, such as GuestUser, instead of nil. The caller can use ordinary operations, while the object supplies appropriate restricted behavior.

This is the output side of chapter 4's Special Case pattern. It is appropriate when the returned object honestly represents the situation. It is inappropriate when it merely hides a missing required entity or failed authentication.

**Contract cost:** once the public method returns a truthy object instead of nil, existing callers' conditions may change. Migrate them deliberately.

## 5.5 Return a status object

**When:** a command has outcomes more nuanced than success/failure, and callers need details.

**How:** represent the result with named predicates and retain the underlying error where applicable. The source import has three outcomes: a new purchase, an already imported purchase, and a failed attempt.

A status object is stronger than a collection of magic symbols when callers need diagnostic context. It is also a new API and class to maintain; a small boolean-returning operation need not adopt it automatically.

**Failure mode:** catching every StandardError around both the command and its clients can hide programming defects. Preserve exceptions not deliberately represented by the outcome contract.

## 5.6 Yield a status object

**When:** the status contract is useful, but callback-style or batch handling better matches the command's interface.

**How:** yield a status object that provides outcome-specific callback methods. Register actions such as `on_success`, `on_redundant`, and `on_failed`. Only the matching action runs; failure supplies its error.

**Why:** the caller says what to do while the command determines when and how often an outcome is delivered. Batch operations can keep the same outer block.

**Trade-offs:** nested blocks are verbose and less familiar than a return value. A guard may mean no status is yielded at all; document whether callbacks occur zero, one, or many times. Yielding alone does not make execution asynchronous.

**Testing:** exercise each outcome, verify its matching action runs with the right payload, and verify nonmatching actions do not run. Checking only that an object responds to the callbacks is not enough.

**Adaptation:** the supplied listing inconsistently spells one callback `on_error` although it defines `on_failed`. The reconstruction uses `on_failed` consistently. Callback exceptions propagate rather than being recategorized as failed operation outcomes.

## 5.7 Signal early termination with throw

**When:** a deeply nested operation should stop normally through intervening calls that do not inspect your return values.

**How:** establish a matching `catch` at the owner of the operation and `throw` its tag when enough work has been done. The source SAX excerpt parser stops after collecting sufficient text. Returning a sentinel from its character callback cannot stop a parser that ignores that return value.

This is non-error control flow. Do not invent a special exception merely to announce successful early completion when a deliberate catch/throw boundary fits.

**Failure modes:** a missing matching catch causes an uncaught-throw error; a shared tag can be intercepted by an unintended catch; frequent nonlocal exits become hard to follow. Prefer ordinary local return or loop termination when possible. The author presents this as an uncommon tool, especially in application code.

## Decision table

| Caller needs | Start with | Cost to keep visible |
|---|---|---|
| Zero, one, or many records | Consistent array | No-results must differ from operational failure when required |
| Nonessential optional output | Benign value | Loss of failure detail |
| Meaningful alternate role | Special Case | Behavioral compatibility and truthiness changes |
| Action on a successful change | Success callback | Cardinality, retries, client failure |
| Several outcomes plus details | Returned status | Additional interface and explicit handling |
| Event-style or batch outcomes | Yielded status | Nesting and whether callbacks run |
| Normal early exit across parser calls | catch/throw | Nonlocal control flow and matched tags |

## Worked example: a result shape callers can trust

This compact reconstruction replaces the source's operating-system dictionary with an in-memory collection and avoids interpolating a prefix into a regular expression.

```ruby
def matching_words(words, prefix)
  return [] if prefix.empty?

  words.select { |word| word.start_with?(prefix) }
end
```

For `words = %w[ruby rust python]`, the results for `"ru"`, `"py"`, and `"missing"` have cardinalities two, one, and zero, but always remain arrays. A caller can use `.map(&:upcase)` for every case, including the empty-prefix guard.

The work does not need a case statement about how many results it found. Its absence is more useful than a new abstraction.

## Worked example: explicit status callbacks

This reconstruction models outcome dispatch only. It does not perform a database import.

```ruby
class ImportOutcome
  def initialize(state, error = nil)
    unless [:success, :redundant, :failed].include?(state)
      raise ArgumentError, "Unknown import outcome"
    end
    @state, @error = state, error
  end

  def on_success
    yield if @state == :success
  end

  def on_redundant
    yield if @state == :redundant
  end

  def on_failed
    yield @error if @state == :failed
  end
end
```

A command can yield one of these objects. The client supplies a success action, a redundant-import action, and a failure action. Only the applicable one runs. The object keeps the original error available to that action.

When integrating this with a real importer, keep the protected operation's exception handling distinct from executing client callbacks. Otherwise a broken notification callback might be mistaken for a failed import that should be retried.

## Key concepts

- **Result shape:** the operations callers can depend on without asking which branch produced the value.
- **Command:** an operation whose purpose is an effect.
- **Query:** an operation whose purpose is information.
- **Status object:** an explicit representation of an operation's outcome and context.
- **Callback cardinality:** the number of times a handler may run.
- **Sentinel:** a distinguished result that communicates a special condition, useful only when its receiver honors it.

## Takeaways

1. Review every exit path, including guards, against the outward contract.
2. Choose the smallest result representation that preserves meaning the caller needs.
3. Keep errors when diagnostic information matters.
4. Make zero/many callback behavior part of the interface.
5. Do not confuse normal early completion with failure.

## Connects to

[Chapter 4](ch04-collecting-input.md) covers Array(), special cases, and policy blocks from the input side. [Chapter 6](ch06-handling-failure.md) focuses on recovery boundaries. [Chapter 7](ch07-refactoring-for-confidence.md) demonstrates preserving legacy caller behavior.
