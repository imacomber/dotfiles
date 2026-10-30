---
name: exceptional-ruby
description: "Apply Avdi Grimm's Exceptional Ruby when designing, reviewing, or testing Ruby failure handling: exception contracts, rescue/else/ensure scope, causes and diagnostics, bounded retry, caller fallback policies, bulkheads, circuit breakers, exception safety, and library error APIs. Also use for studying or looking up the book's sections and appendices."
---

# Exceptional Ruby

**Author:** Avdi Grimm. **Source:** supplied 2011 book, 102 PDF pages. **Generated:** 2026-10-30. **Coverage:** 7 main sections and 2 appendices, numbered here for navigation; the book's section headings are unnumbered.

Design failure handling as part of an operation's contract. Choose how to signal failure, where policy belongs, which state must survive interruption, and how diagnostics reach someone who can act.

## How to use

- For code review, identify the promised outcome, expected negative outcomes, recovery owner, protected scope, state effects, and diagnostics before suggesting a change.
- Read the indexed reference before answering a detailed topic question. `ch03` covers mechanics; `ch06` covers strategy; `appA` covers failure injection.
- Consult [cheatsheet.md](cheatsheet.md) for decisions, [patterns.md](patterns.md) for techniques, and [glossary.md](glossary.md) for terminology.
- Distinguish source guidance from **Adaptation** notes and version corrections. Follow project conventions; this catalog does not require a new abstraction for every method.
- Examples are compact reconstructions, not verbatim listings. Current-language notes are bounded by the linked official references and the runtime used for checks.

## Core frameworks

### Failure as a breach of contract

The book distinguishes an **error** (an implementation defect), a **failure** (inability to fulfill a purpose), and an **exception** (an abnormal condition encountered during execution). These meanings are more precise than casual usage.

For each operation, identify preconditions, promised results/effects, and the object invariant. A method that receives valid inputs but cannot deliver its postconditions or preserve its invariant has failed. An invariant protecting usable state need not include every business validation rule.

Before coding recovery, decide what continuing would mean. A rescued exception is not evidence that the operation succeeded.

### Five questions before raising

1. **Is the situation truly unexpected?** Invalid user input and ordinary negative answers may belong to normal flow.
2. **Am I prepared to end the program?** An uncaught exception can end the process, thread, request, or framework-owned work unit. Is that appropriate for this condition?
3. **Can I punt the decision up the call chain?** A caller-supplied fallback may be better informed than the callee.
4. **Am I throwing away valuable diagnostics?** Preserve expensive partial results, context, and the original failure when useful.
5. **Would continuing result in a less informative exception?** Reject a broken precondition close to its origin rather than waiting for a remote nil failure.

These questions balance fail-fast behavior with deliberate degradation. They are not a universal preference for either swallowing errors or terminating immediately.

### Separate expected flow from exceptional failure

A normal missing result can be a documented value, result/status object, callback, or caller-selected fallback. Use `catch`/`throw` when normal early completion must cross intervening calls; use a local return or loop exit when sufficient. Ruby throw/catch is separate from raise/rescue.

Whether an event is exceptional depends on the contract: a missing file, EOF, or HTTP response can be normal in one operation and a failure in another. Do not infer policy from a low-level exception class alone.

### Own rescue scope deliberately

A bare rescue handles StandardError descendants, not every Exception. Put specific handlers before general ones. A short expression with `rescue nil` still swallows all StandardError failures from that expression, including programming mistakes.

Use method-level rescue or a **Contingency Method** when that makes the protected operation and repeated policy clear. Moving a rescue changes what it can catch. Keep client callbacks outside a library operation's rescue when their failures must propagate.

Use **else** for success-only work that must not be rescued by the preceding handlers. Use **ensure** for small cleanup that belongs on success and failure paths. Avoid explicit return in ensure: it can suppress an in-flight exception. Cleanup can fail too; preserve the primary error and all required cleanup obligations.

### Preserve diagnostics across abstraction boundaries

Use bare `raise` to propagate the active exception without replacing it. When translating an external error to a domain error, preserve its cause and relevant context. Prefer an error class that callers can handle deliberately to a generic message requiring text matching.

**Version correction:** the book implements nested exceptions manually because its Ruby lacked built-in chaining. Ruby 3.4 supplies `Exception#cause`, and `raise(..., cause: error)` explicitly selects it; an active exception is the default cause. Prefer these facilities where supported. [Exception documentation](https://docs.ruby-lang.org/en/3.4/Exception.html#method-i-cause), [Kernel raise documentation](https://docs.ruby-lang.org/en/3.4/Kernel.html#method-i-raise).

Retain useful provenance without logging secrets or dumping arbitrary user objects. Do not add a wrapping class or dependency if propagating the original error already conveys the right contract.

### Retry a defined operation, with a stopping rule

Ruby retry restarts the associated protected body. Keep the attempt counter outside that body and limit the attempts. Identify the exact transient failures that justify retry, what state resets, and which effects might already have occurred.

**Adaptation:** for real systems, decide idempotency, deadline/backoff, and scheduling at the correct layer. A network error does not prove that a remote effect did not happen. A small local example is not a production retry policy, and not every failure should be retried.

### Contain failures, including failures in reporting

An error reporter can cause a cascade when the destination fails or is overwhelmed. A **bulkhead** limits the damage crossing a subsystem boundary. Its own fallback must be dependable and must not silently convert required work into success.

A **Circuit Breaker** gates repeated dependency attempts: closed permits normal operations and counts relevant failures; open rejects or degrades without attempting the dependency; half-open permits a probe and reopens on failure. Choose thresholds, timing, and fallback for the workload; the book provides no universal values.

The source's illustrative bulkhead rescues Exception. **Adaptation:** broad containment needs a specific boundary and propagation policy; application code should not casually swallow shutdown, interrupt, or resource-exhaustion exceptions. Protect reporting separately from the original operation.

### The three exception-safety guarantees

| Guarantee, using the book's names | Promise on failure | Evidence to seek |
|---|---|---|
| Weak | State remains consistent | Invariants and resource ownership survive interruption |
| Strong | State returns to its starting condition | No partial externally visible change, or reliable rollback |
| Nothrow | Method handles failures internally | Defined result/fallback and no escaping exceptions within its declared scope |

No guarantee is a fourth possibility, not a satisfactory default for critical code. Nothrow does not mean the operation succeeds. Strong exception safety does not follow merely from using ensure or rescuing an error.

Use failure injection for critical transitions: establish fresh state, force a failure at a selected call boundary, then assert the promised state and resource behavior. The book's record/playback tester is a proof of concept, not proof against every possible interruption. Asynchronous failures, process termination, external services, and concurrency require separate reasoning.

### Shape the error API for its users

Namespace application/library errors under an appropriate base type when callers benefit from a coherent family. Translating an exception changes what existing rescue clauses match. The source offers module tagging as an alternative that preserves concrete class identity while adding a rescuable category; this mutates the exception and is not always the simplest choice.

The **three essential exception classes** organize failures by response:

- **User Error:** caller/user can correct the problem.
- **Logic Error:** the implementation or its use needs correction; report diagnostics.
- **Transient Failure:** a temporarily unavailable resource may recover; retry/defer only under a sound policy.

The source additionally distinguishes InternalError and ClientError within library logic failures. These are design categories, not mandatory classes or built-in Ruby types. Ordinary validation need not become an exception just to fit the taxonomy.

For complex multi-step work, **process reification** gives a domain object a place to hold results and problems. For a small operation, a value or caller policy may suffice. A **no-raise API** makes represented failures inspectable without throwing them, but must clearly state its scope; it must not silently swallow client callback bugs or claim immunity to process death.

## Reference index

| Reference | Source section | Printed pages | Principal material |
|---|---|---|---|
| [ch01](chapters/ch01-introduction.md) | Introduction | 14 | Coherent strategy; mechanics and policy |
| [ch02](chapters/ch02-what-is-a-failure.md) | What is a failure? | 15-17 | Definitions; Design by Contract; failure causes |
| [ch03](chapters/ch03-exception-lifecycle.md) | The life-cycle of an exception | 18-48 | raise, rescue, retry, else, ensure, causes, threads |
| [ch04](chapters/ch04-responding-to-failures.md) | Responding to failures | 49-55 | Benign values; reporting; bulkheads; circuit breakers; exit |
| [ch05](chapters/ch05-alternatives-to-exceptions.md) | Alternatives to exceptions | 56-63 | Sidebands; transcripts; policies; process objects |
| [ch06](chapters/ch06-failure-handling-strategy.md) | Your failure handling strategy | 64-86 | Five questions; guarantees; failure testing; error API design |
| [ch07](chapters/ch07-conclusion.md) | Conclusion | 87 | Closing perspective; no additional technique |
| [appA](chapters/appendix-a-exception-testing.md) | Exception tester implementation | 89-93 | Record/playback experiment; swap example; limitations |
| [appB](chapters/appendix-b-standard-exceptions.md) | An incomplete tour of ruby's standard exceptions | 94-102 | StandardError boundary; selected exception families; historical notes |

The section numbers above are generated navigation labels. The extractor mistook the 56-item listing index for chapters; it was corrected using the source contents and headings.

## Topic index

| Topic | Read |
|---|---|
| abort; at_exit; exit; exit!; SystemExit | ch03: Uncaught exceptions; ch04: Ending the program |
| Backtrace; caller; exception protocol; $! | ch03: Raising and unwinding |
| Benign values; nil flags; graceful degradation | ch04: Failure flags and benign values |
| Bulkheads; cascading failures; reporting | ch04: Remote failure reporting |
| Caller-supplied fallback; fetch; detect | ch05: Caller-supplied fallback strategy; ch06: Let callers choose |
| catch/throw; expected nonlocal completion | ch06: Use throw for expected cases |
| Cause; exception wrapping; re-raising | ch03: raise during exception handling; ch06: Namespace your own exceptions |
| Circuit Breaker; closed/open/half-open | ch04: The Circuit Breaker pattern |
| ClientError; InternalError; Logic Error | ch06: Three essential exception classes |
| Consistency versus validity; invariant | ch02; ch06: Exception Safety |
| Contingency Method; isolated rescue policy | ch06: Isolate exception handling code |
| Dynamic rescue; matcher modules; rescue modifier | ch03: Coming to the rescue |
| else; success callbacks outside rescue | ch03: else |
| ensure; cleanup; return suppression | ch03: ensure |
| Exception Safety; weak/strong/nothrow | ch06: Exception Safety; appA |
| Failure injection; record/playback; tracing | appA |
| Error/failure/exception definitions; contract | ch02 |
| Five questions before raising | ch06: Some questions before raising |
| Module tags; exception namespace; library boundary | ch06: Tagging exceptions with modules |
| No-raise API; response/status object | ch06: The no-raise library API |
| Performance; exceptions as normal control flow | ch03: Are Ruby exceptions slow? |
| Process reification; problems collection | ch05: Process reification |
| Retry; attempt boundaries; transient failure | ch03: retry; ch06: Three essential exception classes |
| ScriptError; NotImplementedError; StandardError; Errno | appB |
| Sideband data; multiple results; transcript | ch05 |
| Thread failures; report_on_exception; local state | ch03: Exceptions in threads; ch05: Global variables |
| Timeout::Error; SecurityError; obsolete $SAFE | appB |
| User Error; validation | ch06: Three essential exception classes |
| Warnings; warn; development diagnostics | ch04: Reporting failure to the console |

## Scope and source record

Synthesized personal study and coding reference, not a replacement for the book. Source: exceptional-ruby.pdf, Avdi Grimm, copyright 2011; 584,393 bytes, SHA-256 `0a5553efbb02774c0f8134e39904c2fd115943de7774cedd11805832571fc17c`. About 22,569 extracted words / 30,092 estimated tokens, including front/back matter. Converter: book-to-skill. Requested technical extraction; actual pdftotext fallback because Docling was unavailable. Diagrams were not interpreted; no reliable omitted-image count was provided.

About/history, acknowledgements, and bibliography supply context rather than additional technique files. Purchaser details, raw book text, full historical listings, and OS-specific error-code tables are not bundled. Modern-language corrections are explicitly marked and linked; no claim is made that the book's third-party gem examples remain supported. Runnable reconstructions are checked on the available Ruby runtime, not every Ruby version. No publication or remote upload is part of this conversion.
