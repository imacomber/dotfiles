# Confident Ruby decision sheet

## Choose the representation

| When you see | Do this | Because | Source |
|---|---|---|---|
| Input preparation interrupts the main task | Gather/normalize it before the work | Readers can follow one role at a time | 2, 4.1 |
| Existing library details dictate every step | Name domain messages and receivers first | Incidental tools should not define the story | 3 |
| Same nil/type check in several internal methods | Resolve it at the owning boundary | One dependable contract beats distributed doubt | 4.1 |
| Compatible object, wrong representation | Use a meaningful conversion | Preserve flexibility without repeated branching | 4.2-4.8 |
| No acceptable interpretation exists | Reject before mutation/effects | A delayed error may follow partial damage | 4.12 |
| Required hash key; false/nil can be deliberate | fetch, then validate value separately | Presence is different from truthiness | 4.13 |
| Computed default only for omission | fetch with a block | Preserve supplied values and defer computation | 4.14 |
| Unusual case completes the method | Visible guard with correct result | The normal work need not remain nested | 4.16 |
| One alternate situation affects many operations | Special Case object | Centralize coherent alternate behavior | 4.17 |
| Absence means no interaction | Narrow Null Object | Remove repeated guards without inventing work | 4.18 |
| Missing nonessential information | Honest benign fallback | Optional data should not dominate the method | 4.19 |
| Optional value should fail clearly if later used | Descriptive symbolic placeholder | Error provenance improves cheaply | 4.20 |
| Same cohesive argument bundle everywhere | Parameter object | A named concept can attract its behavior | 4.21 |
| Construction of those objects burdens clients | Yield parameter; builder only if needed | Hide complex combinations without exposing them | 4.22 |
| Multiple flags select edge behavior | Named caller policy | Caller has the context for its own decision | 4.23 |

## Choose strictness deliberately

- Already satisfies the role? Send the message; do not add redundant conversion.
- String-like/integer-like/array-like contract? Consider to_str/to_int/to_ary.
- Broad display representation? to_s may be appropriate; do not use it to validate a required identifier.
- Parsed numeric text must reject nonsense? Integer()/Float(), with domain/base/range decisions made explicitly.
- None/one/many interface? Array(); remember a hash becomes pairs.
- Several state-dependent operations switch on the same primitive? Consider a behavior-bearing object; one switch alone is weak evidence.
- External schema uncertain? Assert at the boundary; trusted internals need not repeat the same checks.

## Choose an outward contract

| Need | Default candidate | Reason to choose something else |
|---|---|---|
| Collection query | Array for zero/one/many | Failure must remain distinguishable from empty |
| Optional rendered fragment | Empty string | Caller needs failure diagnostics |
| Meaningful missing entity | Special Case | Absence violates a required invariant |
| Action when a change occurs | Success callback | Caller only needs a simple value |
| Several outcomes and detail | Returned status | Additional API costs more than it helps |
| Batch/event outcomes | Yielded status | Nested callbacks or cardinality are unclear |
| Normal nonlocal completion | catch/throw | Local return/break can express it |

## Failure placement

- One known exception from an external operation: checked helper.
- Nonexception failure status: bouncer method.
- Whole method truly shares recovery: method-level rescue.
- Different callers need different recovery: policy block/proc.
- More and more policy arguments: reconsider responsibility boundaries.

## Fast checks before accepting a refactoring

- Do all result paths, including guards, satisfy the outward contract?
- Does explicit nil still behave as promised? A default argument does not handle it.
- Do false-valued options survive defaults?
- Did rescue move across callbacks or newly protected work?
- Are cleanup, side effects, error identity, and ordering preserved?
- Can a caller mutate a cache key or nested supposedly immutable value?
- Does a new special object change authentication checks because it is truthy?
- Does the wrapper actually implement the required role and its semantics?

The last checks include adaptation safeguards; they are not additional named book patterns. The book gives no universal line-count, class-count, or nesting threshold.
