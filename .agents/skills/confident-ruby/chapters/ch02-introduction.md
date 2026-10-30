# Chapter 2: Introduction

**Source:** printed pp. 7-17.

## Core idea

A method should tell a coherent story about its task. Nested exceptions to the story make readers carry unnecessary mental state, even when every individual line seems defensible.

## Framework: the four parts of a method

| Part | Question | Typical content |
|---|---|---|
| Collecting input | What do I need, and can I rely on it? | Lookups, argument normalization, boundary checks |
| Performing work | What is this method here to do? | Domain operations on prepared collaborators |
| Delivering output | What contract does the caller receive? | Return value, collection, callback |
| Handling failures | What happens when the task fails? | Recovery or propagation with meaningful context |

Diagnostics and cleanup are additional categories that sometimes appear. Not every method needs an explicit section for every part. The desired separation is about comprehension, not mandatory comments or four helper methods.

## How to apply it

1. State the method's central task in one sentence.
2. Mark each existing line as input, work, output, failure, diagnostics, or cleanup.
3. Notice alternation: input followed by rescue followed by more input followed by work usually indicates a narrative interruption.
4. Group closely related operations and establish input assumptions before the main work.
5. Make early failures visible without wrapping the normal path in a large else branch.
6. Check that results and failure behavior remain correct at every exit.

**Why it works:** a reader can understand one responsibility at a time instead of constantly revising the conditions under which the next line runs.

**Failure mode:** moving checks only to create a prettier sequence can change which errors win, which effects occur, and which resources are cleaned up. Organization is subordinate to behavior.

## Worked example: locating analysis results

The introduction's MetricFu example retrieves a subtable, checks for missing data, takes its first row, and selects different location fields based on whether the caller asked about a file, class, or method. Most normal work sits inside an else branch introduced by the empty-data failure.

A compact reconstruction of its evolution:

1. Fetch the subtable: input collection.
2. Reject the empty subtable: a precondition, before dereferencing its first row.
3. Select the first row: remaining input collection.
4. Build the requested location: work and returned result.
5. Retain rejection of unsupported request kinds: do not silently return nil.

The first improvement can be as small as removing the else after an unconditional raise. A later improvement can name the data-presence check, making the main method read as a sequence of intentions. Chapter 7 revisits this example in detail.

## Key concepts

- **Code as narrative:** the sequence communicates why each step exists.
- **Timid code:** uncertainty and special handling repeatedly interrupt the task.
- **Cognitive burden:** readers must retain conditions and partial assumptions while moving through the method.
- **Implementation pattern:** a small construction technique, often an idiom rather than architecture.
- **Happy path:** the ordinary execution story, kept distinguishable from exceptional handling.

## Mental models

- Read a method like a page: excessive conditional backtracking makes its story hard to follow.
- A check can be necessary but badly placed; ask whether it establishes input, performs work, or handles failure.
- Treat the catalog as alternatives for a problem already observed, not a list of features to install.

## Anti-patterns

- Mixing validation, output assembly, and rescue stanzas without an intentional order.
- Hiding the actual work under branches whose sole purpose is rejecting unusable input.
- Equating confidence with removing validation or ignoring operational failures.
- Extracting helpers that merely shuffle lines without clarifying responsibilities.

## Takeaways

1. Review the method's structure before choosing a pattern.
2. Preserve a clear distinction between preparing collaborators and asking them to work.
3. Let the result contract and error contract be as readable as the main operation.
4. Use small changes that make intent more evident.

## Connects to

[Chapter 3](ch03-performing-work.md) identifies the messages the work should contain. [Chapter 4](ch04-collecting-input.md) prepares its collaborators. [Chapters 5](ch05-delivering-results.md) and [6](ch06-handling-failure.md) address the other two phases. [Chapter 7](ch07-refactoring-for-confidence.md) applies the ideas to existing code.
