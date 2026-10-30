# Your failure handling strategy

Source: printed pages 64–86. Contents: expected cases; throw; caller policy; five questions; Contingency Method; Exception Safety; selective handling; exception API design.

## Core idea

Design a failure strategy around caller decisions and state guarantees. Exception classes, rescue locations, and fallback values are parts of that strategy, not isolated syntax choices.

## Expect the unexpected — and do not make it expected flow

The book's rule of thumb asks whether the ordinary program would still make sense if exception handling were removed. If removing handlers destroys the normal successful path, exceptions may be doing routine branching work. Use this as a review heuristic, not an instruction to delete reliability boundaries or recovery policy.

An event is exceptional relative to a particular contract. A lookup that promises an optional answer can return absence; a required lookup may properly raise. EOF can be ordinary iteration completion or an unexpectedly truncated record. “Files sometimes go missing” is not enough to choose one response for every method.

### Use throw for expected cases

Ruby catch/throw supports expected nonlocal completion across intervening calls. It is separate from raise/rescue. Use it when a local return or break cannot clearly express the desired exit; avoid hiding distant control transfer behind an ordinary-looking helper call.

```ruby
def book_find_pair(rows, target)
  catch(:book_pair_found) do
    rows.each do |row|
      row.each do |value|
        throw :book_pair_found, value if value == target
      end
    end
    nil
  end
end
```

Finding the value is success, not failure. No rescue is needed to express that success. An unrelated error from iteration still propagates. A missing matching catch is an error; tags and ownership should be visible. Unique object tags can avoid collisions in reusable nested abstractions, but a fixed local example does not require that extra mechanism.

### Let callers choose

Prefer a caller fallback when the caller knows whether missing data is acceptable. Hash#fetch illustrates the difference between “key missing” and “value is nil/false.” A library should not silently choose a business default because it happens to be easy to return nil.

Keep fallback execution outside unrelated rescue scope. If client policy fails, let it fail as client policy. Reclassifying it as a dependency outage hides the actual defect.

## Some questions before raising

Use the source's five questions as an actual decision procedure:

1. **Is the situation truly unexpected?** If it is a regular negative answer, first consider ordinary results or caller fallback. If it violates a promise, an exception may be appropriate.
2. **Am I prepared to end the program?** Decide what should happen if nobody handles the error. The owning boundary may be a process, worker, request, or job; understand which one applies.
3. **Can I punt the decision up the call chain?** Let better-informed callers choose a fallback, retry, or stop. Punting does not mean discarding context.
4. **Am I throwing away valuable diagnostics?** Retain partial results, the cause, and identifying context when they help the caller. Avoid preserving secrets or huge irrelevant object graphs.
5. **Would continuing result in a less informative exception?** Reject an unusable precondition early rather than letting a misleading downstream error obscure it.

The questions can pull in opposite directions. Balance them with the contract. Early rejection preserves evidence; caller fallback preserves flexibility; collecting partial work preserves useful results. None is the universal answer.

## Isolate exception handling code

Keep recovery close to a clearly named operation boundary. Avoid interleaving the successful computation with repeated rescue bookkeeping. Method-level rescue can be clear when the entire method has one failure policy.

### The Contingency Method

Extract a repeated, specific contingency into a small method. Name the protected work and return a truthful fallback. The source's IO-oriented example contains a bare rescue; this reconstruction narrows it to the intended IOError.

```ruby
def book_optional_read(reader)
  reader.read
rescue IOError
  nil
end
```

Use only when unreadability is explicitly equivalent to optional absence. The method does not swallow ArgumentError or other programming failures. If callers must distinguish absent content from failed reading, choose a richer return contract or propagate instead.

Why it works: one policy has one visible owner, and the caller's successful path stays readable. Failure mode: generic helpers such as ignore_errors can spread silent failure across unrelated contracts and erase the reason each fallback was acceptable.

## Exception Safety

Exception safety asks what remains true when an operation is interrupted. A handler that returns a friendly message can still leave corrupted state.

### The three guarantees

| Book's name | Guarantee | Example test question |
|---|---|---|
| Weak | State remains consistent | Are invariants and resource ownership preserved? |
| Strong | State returns to its starting condition | Has every visible mutation been avoided or undone? |
| Nothrow | Failures are handled internally within the method's declared scope | Is there a defined outcome without an escaping exception? |

The source also recognizes no guarantee. Do not silently assume the strong guarantee just because the success path is short. These promises apply to a specified failure model; no Ruby method can guarantee survival of all external termination or machine failure.

Weak is often comparable to the basic exception-safety guarantee in other literature, but retain the book's word “weak” when explaining its framework. Nothrow is not successful completion: a method can return a documented failed result and satisfy its scoped no-escape contract.

### Consistency versus validity

A business object can contain rejected or incomplete input while remaining internally consistent. A validation failure does not require rolling an object back to a previously valid business state unless that is the operation's promise. Conversely, an object passing superficial validation can still have inconsistent relationships after partial mutation.

Choose invariants that callers can rely on. For a collection transformation, weak safety might preserve a structurally usable collection; strong safety requires the original contents to remain unchanged on failure. For a file operation, consider both the file and resource ownership, not just an in-memory return value.

### When can exceptions happen?

Every invoked operation can potentially fail, including conversion, allocation, callbacks, setters, logging, and cleanup. The source uses this observation to expose assumptions in apparently simple mutation sequences.

Do not respond by wrapping every line in rescue. Instead, identify critical transitions and reduce the amount of state exposed between them. Prepare new state before committing it, use an appropriate transaction for owned resources, or design explicit rollback. External effects and concurrency may make a strong guarantee substantially harder than local assignment suggests.

### Testing exception safety

Establish fresh state, choose a failure point, run the operation, and assert the promised state after the forced exception. Repeat at the relevant points. The source's record/playback experiment discovers call boundaries and injects failures into later runs.

A test that only expects an exception proves nothing about state. A test that exercises one failure proves nothing about all the other boundaries. The [appendix reference](appendix-a-exception-testing.md) reconstructs a small swap test and explains the original harness's limits.

**Adaptation:** database transactions, external idempotency, synchronization, and asynchronous interruption require their own checks. Do not claim a local fault-injection harness proves a distributed operation atomic.

## Handling selected exception types

Swallow only a failure whose meaning and fallback are understood. A narrow rescue is often safer than a broad one, but class specificity alone is insufficient: the protected region can still include an unrelated callback that raises the same class.

Use specific handlers before general ones. Preserve propagation for failures outside the recovery promise. Reporting an unexpected error and continuing is only valid if the remaining state and output still meet the chosen contract.

## Namespace your own exceptions

A library error family gives callers a stable way to catch its failures without depending on implementation details. Use a base error below StandardError unless a deliberate exceptional boundary requires otherwise.

Translate at an abstraction boundary when the caller benefits from a domain meaning. Preserve the original cause and relevant structured context. Do not wrap every error merely for visual consistency; wrapping changes concrete types and therefore changes existing rescue behavior.

The book's nested-error implementation is historical. On modern Ruby, use built-in cause rather than patching Exception or Kernel. See the version correction and references in [the lifecycle section](ch03-exception-lifecycle.md).

### Tagging exceptions with modules

The source presents module tagging when callers need both an original low-level class and a library category. Extending the exception adds the category without replacing the object.

```ruby
module BookLibraryFailure; end

class BookTaggedReader
  def initialize(reader)
    @reader = reader
  end

  def read
    @reader.read
  rescue IOError => error
    error.extend(BookLibraryFailure)
    raise
  end
end
```

The propagated error still matches IOError and also matches BookLibraryFailure in a rescue clause. Bare raise preserves the original object and backtrace. This can be useful when translating to a new class would break callers.

Trade-offs: tagging mutates the exception, cannot extend a frozen exception, and can make origin less obvious when multiple libraries tag shared errors. Tag only errors from the operation the library owns; do not attach library blame to arbitrary client callback failures. A small namespaced error class is usually easier when retaining the concrete external type is unnecessary.

## The no-raise library API

A no-raise API makes represented failures inspectable as data, status, a process object, or an explicit callback. State exactly which conditions it represents and how callers determine success. The API still needs diagnostics and state guarantees.

Separate predictable failures from bugs and infrastructure outside the promise. An API that swallows every StandardError may hide defects; an API that swallows Exception can interfere with shutdown or interruption. Arbitrary client callbacks can also fail. Do not promise universal no-escape behavior merely because an implementation has a wide rescue clause.

When translating a raising API to a result API, preserve the meaning of partial output. If completion is required, a problems collection must make incomplete work unmistakable. See [process reification](ch05-alternatives-to-exceptions.md).

## Three essential exception classes

Organize categories around what someone can do about a failure:

| Category | Typical owner/action | Poor response |
|---|---|---|
| User Error | User or caller corrects input/request | Automatic retries of unchanged input |
| Logic Error | Engineer investigates implementation/use | Treating a bug as temporary unavailability |
| Transient Failure | Caller defers, retries, or degrades under a policy | Infinite retries or immediate global termination |

These are conceptual categories, not existing Ruby constants or an instruction to add three classes everywhere. A normal validation result may be more appropriate than a UserError exception. A transient failure classification permits evaluating retry; it does not establish idempotency or a recovery deadline.

### The user perspective

Design error names and attributes around the caller's response, not merely the internal subsystem where something failed. A caller cares whether the request can be corrected or safely attempted later. Low-level causes remain available for diagnostics without forcing callers to understand every implementation detail.

For library logic errors, the source further distinguishes **InternalError** (library implementation defect) and **ClientError** (incorrect library use). Add this distinction only if it helps users respond. Do not copy source-era prevalence estimates as universal facts.

### Defining classes

Use a small stable hierarchy, coherent messages, and structured attributes when useful. A base error lets callers catch a family; subclasses should justify different handling. Avoid generating many classes that all lead to the same response.

## Worked strategy review

For a parser library: malformed input supplied by an end user may become a normal validation result or a correctable input error; an invalid API option is caller misuse; a missing temporary dependency may be transient; an impossible internal parse state is a logic defect. Keep client success callbacks outside parsing rescue. Preserve the input location in diagnostics, but avoid copying private content unnecessarily. If parsing mutates a shared document, define whether failure leaves the old document intact or a consistent partial document.

This review uses all three axes: signal, owner, and state guarantee. Classifying the exception alone is not enough.

## Takeaways

Ask the five questions before raising. Give recovery a named boundary. Promise and test state on failure. Shape error categories around caller action, and keep the original evidence through translation.
