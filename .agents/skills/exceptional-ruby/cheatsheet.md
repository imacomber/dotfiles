# Exceptional Ruby decision sheet

Read the [indexed references](SKILL.md) before applying a detailed or historical claim.

## Choose the signal

| If… | Then… | Because… |
|---|---|---|
| Absence is an ordinary valid answer | Return documented absence/status | Exceptions should not carry routine branching |
| Different callers need different absence policies | Offer a fallback block/callable | The caller knows the required outcome |
| A required contract cannot be met | Raise a useful specific error | False success is worse than visible failure |
| Continuing will produce a misleading downstream error | Reject the broken assumption now | Preserve the informative origin |
| Several independent steps yield useful partial work | Collect problems with an explicit completion rule | Retain evidence without pretending completeness |
| Normal completion must escape nested calls | Consider catch/throw | Success is not an exception |

## Five questions before raising

1. Is the situation truly unexpected?
2. Am I prepared to end the program?
3. Can I punt the decision up the call chain?
4. Am I throwing away valuable diagnostics?
5. Would continuing result in a less informative exception?

## Choose the boundary

| Observation | Decision |
|---|---|
| Callback failure is labeled as read failure | Move success callback to else or outside protected scope |
| `rescue nil` wraps a complex expression | Replace with an explicit known contingency |
| Cleanup has explicit return | Remove it; it can suppress the pending failure |
| Reporter failure masks the original | Separate reporting containment and retain both diagnostics |
| Worker thread has no observer | Define who joins/reads its value and owns failure policy |
| Library calls exit on recoverable failure | Give the owning caller the decision |
| Rescue catches Exception | Check shutdown/interrupt propagation and narrow deliberately |

## Preserve evidence

| Need | Use | Watch for |
|---|---|---|
| Propagate unchanged | Bare raise | Constructing a new generic error |
| Translate meaning | Domain error plus cause/context | Breaking existing rescue matches |
| Retain concrete type plus category | Module tag when justified | Mutation and frozen exceptions |
| Handle a library family | Namespaced base error | Excess subclasses with identical responses |

## State guarantees

| Promise needed | Choose | Verify after injected failure |
|---|---|---|
| Usable internal state | Weak | Invariants and resource ownership |
| Original observable state | Strong | No visible partial effect or reliable rollback |
| Represented failure without escape | Scoped nothrow | Defined failed outcome and intact state |

A rescue is not rollback. Ensure is cleanup, not atomicity. A valid business object and a consistent object are different promises.

## Choose the response

| Failure kind | Response | Avoid |
|---|---|---|
| Correctable User Error | Explain what can be corrected | Repeating unchanged input |
| Logic Error | Preserve diagnostics for correction | Relabeling bugs as temporary outages |
| Transient Failure | Consider bounded retry/defer/degrade | Assuming a failed response means no remote effect |
| Optional work fails | Use a truthful benign value | Hiding required failure as empty success |
| Dependency outage amplifies | Bulkhead damage; circuit-break future calls | Adding another fragile fallback dependency |

Retry only a defined operation: counter outside the body, finite attempts, selected failures, safe repeated effects. Timing/thresholds are workload-specific; the book gives no universal values.

## Version traps

- Source-era nested-exception patches: use modern built-in cause where available.
- Bare rescue: StandardError; excludes NotImplementedError, Interrupt, and SystemExit.
- IOError: does not include SystemCallError/Errno.
- Thread errors: reporting and propagation are different; modern reporting defaults differ from 2011.
- Thread.current brackets: fiber-local in the linked modern Ruby documentation.
- $SAFE: historical, not a current sandbox.
