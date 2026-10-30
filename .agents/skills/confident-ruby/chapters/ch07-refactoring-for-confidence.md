# Chapter 7: Refactoring for Confidence

**Source:** printed pp. 265-279; sections 7.1 MetricFu and 7.2 Stringer.

## Core idea

Real refactoring combines small patterns with investigation of actual callers. Improve the story incrementally while preserving valid inputs, result behavior, state ownership, and failure handling.

## 7.1 MetricFu

### Location cache: use fetch and defer construction

The source's Location.get checks a cache, otherwise creates and freezes a location. It also duplicates several inputs before knowing whether the cache already contains a result.

**How to reason through the change:**

1. Recognize a presence test plus retrieval as a candidate for fetch with a block.
2. Keep the cache-hit path short and free of unnecessary work.
3. Move construction-only work into the miss path.
4. Group operations that establish the new object's final state.
5. Confirm that the returned object remains the intended cached object.

The source extracts a finalize method to group copying location attributes and freezing the location.

**Adaptation limits:** freezing an object does not recursively freeze referenced strings. Cache keys must also remain stable if callers can mutate their original strings. The printed discussion motivates organization but is not proof of deep immutability, thread safety, or a complete cache design. Verify these independently when relevant to a real change.

### Location initializer: benign string conversion

A method name may be absent, making string substitution awkward. The source uses `to_s` so nil becomes an empty string and the substitution can proceed uniformly.

**When useful:** empty text honestly represents the absent optional value.

**What to check:** changing an old nil result to an empty string is an outward semantic change if callers distinguish them. Do not use this technique for required identifiers merely to avoid errors.

### HotspotAnalyzedProblems: promote the normal path

An empty analysis subtable causes an exception, but the code places normal processing under the corresponding else.

1. Remove the unnecessary else after the unconditional raise.
2. Bring the normal logic back to the method's top level.
3. Name the precondition if its detailed message still overwhelms the flow.
4. Retrieve the first row only after data presence is established.
5. Retain explicit rejection of unsupported item kinds.

The final method tells a sequence: get subtable, assert usable data, select row, construct location. The objective is visible responsibilities, not eliminating legitimate case distinctions.

### Ranking: inspect explicit nil callers

The original ranking method returns the first N sorted items for numeric N and the entire collection otherwise. A proposed simplification uses the collection's size as the default argument. Investigation reveals callers explicitly passing nil, which overrides any default expression.

The source restores a nil default and normalizes it in the body. This is a useful counterexample to choosing the prettiest one-line signature without examining callers.

**Compatibility detail:** using `||=` also replaces false. The original accepted a wider set of nonnumeric values than the final simplified method. Preserve the actual supported caller contract deliberately; do not call a change behavior-preserving solely because its main example still works.

## 7.2 Stringer

Feed discovery first tries to parse the supplied URL. If that fails, it discovers possible feed URLs and tries the first result. The original contains two similar begin/rescue/end blocks.

**Refactoring:** extract the fetch/parse operation into a checked helper accepting a failure policy, then express the two attempts using that helper. The domain sequence remains visible while repeated recovery detail moves out of the main method.

The source explicitly notices that rescuing Exception can hide defects, but leaves narrowing it as future work. That omission is not a recommendation to introduce the same broad rescue in new code.

## Worked example: preserve explicit nil compatibility

This reconstruction isolates the Ranking lesson:

```ruby
def top_items(sorted_items, count = nil)
  count = sorted_items.size if count.nil?
  sorted_items.first(count)
end
```

- Omitting count returns all entries.
- Explicit nil does the same.
- Zero returns an empty array.
- A positive count returns the corresponding prefix.

The nil-specific normalization is an adaptation, distinguishing nil from false rather than silently treating both as omission. It is not claimed to preserve every historical nonnumeric input. Before changing a real Ranking API, inspect those callers and decide which inputs it promises to support.

## Worked reasoning: a safe extraction of parser recovery

A faithful conceptual reconstruction, without reproducing historical third-party APIs:

1. Assign the result of parsing to a local feed before setting any of its attributes. The supplied helper listing omits that assignment.
2. Fill a missing canonical URL with the URL used for that attempt.
3. Catch only parsing/fetching failures deliberately covered by the contract.
4. Invoke the fallback policy for that expected failure.
5. Let fallback discovery choose whether a second attempt exists.
6. Preserve the original no-feed result while inspecting whether nil versus false matters to clients.

A mechanically copied extraction can inherit a listing typo or broaden rescue scope. A behavior check must demonstrate the original URL success, discovered URL success, no candidates, parse failure, and error propagation that should remain exceptional.

## Key concepts

- **Incremental refactoring:** a sequence of small, reviewable changes with preserved contracts.
- **Cache miss policy:** construction performed only when lookup cannot supply a value.
- **Explicit nil compatibility:** default arguments do not apply when callers pass nil themselves.
- **Benign conversion:** replacing optional absent text with an acceptable empty representation.
- **Checked extraction:** naming an operation together with its intended recovery behavior.

## Anti-patterns

- Improving signatures before searching callers.
- Treating less nesting as evidence that all behavior stayed the same.
- Removing copying, freezing, or cleanup because it obscures the narrative.
- Reproducing a historical listing's typo as a working example.
- Claiming cache correctness or modern library compatibility from the book's organizational example.

## Takeaways

1. Take the small clarity improvement even when it does not complete an ideal redesign.
2. Reuse existing language features such as fetch before adding machinery.
3. Check boundary inputs and edge behavior at each step.
4. Keep concrete semantic differences visible in the review.

## Connects to

[Chapter 2](ch02-introduction.md) introduces the location example. [Chapter 4](ch04-collecting-input.md) covers fetch, preconditions, and benign inputs. [Chapter 6](ch06-handling-failure.md) supplies checked methods and focused rescue.
