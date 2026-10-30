# Glossary

Chapter labels refer to the [reference index](SKILL.md); appA/appB denote appendices.

**Abnormal condition** — An execution condition treated as outside the operation's normal path; not necessarily a programming defect. (ch02)

**Benign value** — A fallback that permits meaningful continued operation under the documented contract. (ch04)

**Breach of contract** — Inability to honor a required precondition, postcondition, or invariant; responsibility depends on which promise failed. (ch02)

**Bulkhead** — A boundary limiting how far a subsystem's failure can spread. (ch04)

**Caller-supplied fallback** — A block/callable through which a better-informed caller selects the response to an expected negative result. (ch05, ch06)

**Cascading failure** — One failure triggers additional failures, such as an unavailable alerting dependency breaking error handlers. (ch04)

**Cause** — The exception underlying another exception; modern Ruby provides built-in chaining, unlike the source-era implementation. (ch03)

**Circuit Breaker** — A dependency gate that opens after relevant failures and later permits a recovery probe. (ch04)

**ClientError** — The source's category for incorrect use of a library, within logic failures. (ch06)

**Consistency** — Preservation of internal relationships that make state usable; distinct from business validity. (ch02, ch06)

**Contingency Method** — A small method isolating a specific, repeated exception-handling policy. (ch06)

**Error** — An implementation defect, using the book's precise terminology. (ch02)

**Exception** — An abnormal execution condition; also the root Ruby exception class when capitalized. (ch02, appB)

**Exception protocol** — Ruby's use of #exception to obtain an exception object when raising. (ch03)

**Exception Safety** — A promise about state and behavior when an operation fails. (ch06, appA)

**Failure** — Inability to fulfill an operation's purpose. (ch02)

**Failure flag** — A result indicating that work failed, requiring a defined caller response. (ch04)

**Failure injection** — Deliberately causing failure at selected boundaries to test post-failure state and behavior. (appA)

**InternalError** — The source's category for a defect within a library implementation. (ch06)

**Invariant** — A condition keeping an object's state internally consistent across public operations. (ch02, ch06)

**Logic Error** — A failure requiring correction to implementation or use rather than an automatic unchanged retry. (ch06)

**Module tagging** — Extending an existing exception with a rescuable module category while retaining its concrete class and identity. (ch06)

**No-raise API** — An API representing its declared failure conditions without throwing them; scope and inspection rules must be explicit. (ch06)

**Nothrow guarantee** — Internally handled failure with no escaping exception within the declared failure model; not a promise of successful work. (ch06)

**Postcondition** — A promised result or effect after successful completion. (ch02)

**Precondition** — A requirement the caller must satisfy before invocation. (ch02)

**Process reification** — Giving a multi-step operation an object that owns its results and problems. (ch05)

**Record/playback testing** — Recording eligible call boundaries, then replaying with injected failures to examine exception safety. (appA)

**Re-raising** — Propagating the active exception with bare raise, preserving its diagnostic identity. (ch03)

**Sideband data** — Status or diagnostic information carried alongside the main result. (ch05)

**StandardError** — The Ruby exception family caught by a bare rescue. (ch03, appB)

**Strong guarantee** — On failure, observable state returns to its starting condition. (ch06)

**Transcript** — A caller-owned collection accumulating an operation's problems or messages. (ch05)

**Transient Failure** — A temporarily unavailable resource or condition that may recover; retry still needs a sound policy. (ch06)

**Unwinding** — Abandoning stack frames toward a handler while running applicable ensure clauses; effects are not automatically rolled back. (ch03)

**User Error** — A condition a user or caller can correct; ordinary validation may represent it without exceptions. (ch06)

**Validity** — Satisfaction of business rules, distinguished from internal consistency. (ch06)

**Weak guarantee** — State remains internally consistent after failure. (ch06)
