# Chapter 4: Collecting Input

**Source:** printed pp. 31-211. Section names and numbers follow the book. This chapter is unusually large because it contains the main input-pattern catalog.

## Core idea

Collecting input means turning the objects available to a method into dependable players of the roles its work needs. Coerce, reject, or substitute at the boundary; avoid distributing the same uncertainty throughout internal methods.

## 4.1 Introduction to collecting input

Inputs include arguments, constants (including class objects), instance variables, other methods' results, time, environment values, configuration files, and external responses. An indirect input requires messages to obtain it; several chained indirect inputs multiply opportunities for surprises.

Identify the work first. For a method formatting a time, locating a preferences file and reading its format are input collection, not the formatting itself. Gather those values into a recognizable stanza before calling the formatter.

**Guard the borders, not the hinterlands:** public library APIs and subsystem entry points are natural places for checking and conversion. Once an object enters a trusted neighborhood, internal code should not repeat all those checks.

## 4.2 Use built-in conversion protocols

**When:** the work needs a core representation while callers may have compatible objects.

**How:** request the conversion whose semantics match the contract. The target type normally implements its own protocol, so already converted inputs also work.

| Representation | Broader explicit conversion | Type-like implicit protocol |
|---|---|---|
| String | `to_s` | `to_str` |
| Integer | `to_i` | `to_int` |
| Array | `to_a` | `to_ary` |
| Hash | `to_h` | `to_hash` |
| Filesystem path string | — | `to_path` |
| Callable block | — | `to_proc` |

A timestamp can be represented as a string without being string-like. A title wrapper may reasonably implement both `to_s` and `to_str`. An index wrapper can implement `to_int` and then be used as an array index.

**Failure mode:** broad conversions can hide incorrect values. `"nonsense".to_i` produces zero. Narrower protocols express stronger requirements but still do not enforce every domain rule.

## 4.3 Conditionally call conversion methods

**When:** an optional protocol adds useful meaning but ordinary accepted values do not implement it.

**How:** optionally call the contextual conversion, then require the underlying representation.

```ruby
def normalized_path(value)
  value = value.to_path if value.respond_to?(:to_path)
  value.to_str
end
```

This supports strings, Pathname-like objects, and caller-defined path objects. It rejects unrelated values without monkey-patching String to implement `to_path`.

The boundary check asks whether an object can *provide* the role, rather than checking whether it belongs to a particular class. Avoid enumerating every method the work might call; such protocol checklists are brittle.

## 4.4 Define your own conversion protocols

**When:** the needed representation has meaning beyond its core container, such as a two-element coordinate pair.

**How:** document a protocol such as `to_coords`; call it when available, then normalize the result to the expected container. Verify shape and domain constraints if those matter. An array conversion alone cannot prove there are exactly two numeric coordinates.

**Trade-off:** a domain-specific protocol permits third-party extension without forcing general array semantics onto an object. It also adds a contract that must be documented.

## 4.5 Define conversions to user-defined types

**When:** arithmetic or other work requires a domain type, yet callers may supply equivalent domain representations.

**How:** define a protocol such as `to_meters`. The target returns itself; another unit supplies a meaningful conversion. Perform internal operations using the normalized domain type.

**Worked reasoning:** the source's altitude example accepts feet and meters but does not accept arbitrary bare numbers as if their unit were obvious. Normalize both altitudes before subtraction. Keep the result a measurement, not an unlabelled numeric value.

**Adaptation:** the book's illustrative conversion rounds to whole meters. Precision and rounding are domain decisions; do not copy that policy into measurement software by default.

## 4.6 Use built-in conversion functions

**When:** accept a range of sensible representations, then work with a core type.

**How:** choose a capitalized function such as `Integer()`, `Float()`, `Array()`, `String()`, or an appropriate standard-library conversion. Each has its own semantics.

`Integer("bad")` rejects text that `"bad".to_i` silently interprets as zero. This does not mean Integer is a complete integer validator: conversion from a float can truncate; strings may use base notation. If the interface promises decimal parsing, choose an explicit base and separately define whether fractional input is permitted.

**Historical note:** the source's claim that Ruby lacks `Hash()` reflects its era. Treat the protocol catalog as historical context rather than a current complete API reference.

## 4.7 Use the Array() conversion function to array-ify inputs

**When:** the API deliberately accepts none, one, or many values.

| Input | Result |
|---|---|
| nil | `[]` |
| `"entry"` | `["entry"]` |
| `[1, 2]` | `[1, 2]` |
| `{a: 1}` | `[[:a, 1]]` |
| `1..3` | `[1, 2, 3]` |

**How:** normalize once, then iterate. Do not flatten nested domain collections accidentally. Do not use `Array()` to wrap a hash record as one record; its conversion semantics are different.

**Why:** the loop can concentrate on processing entries, with no separate branch for each input shape.

## 4.8 Define conversion functions

**When:** the public API accepts several forms but the implementation should use one domain type.

**How:** centralize the accepted cases in a small normalization function. Preserve an existing target instance; delegate caller-defined conversion to a documented protocol. Reject unsupported forms before effects.

The source's `Point()` accepts coordinates, arrays, colon-separated strings, and objects implementing `to_point` or `to_ary`. Its naming follows Ruby's capitalized conversion convention. `module_function` makes a module's functions callable on the module and private when included.

**Adaptation:** examples accepting strings with `split` and `to_i` demonstrate shape conversion, not rigorous parsing. A real untrusted format needs field-count, numeric, and range checks. Do not add a flexible parser when the actual API only needs Point objects.

## 4.9 Replace "string typing" with classes

**When:** many methods switch on the same specially meaningful string, symbol, or number.

**How:** identify the underlying concept, give it behavior, and let dispatch select that behavior. Keep any external string-to-object conversion at one entry point.

**Worked reasoning:** the source traffic light repeatedly switches on stop/caution/proceed, both to select a successor and to operate lamps. Caution also rings a bell. State objects can own both operations, eliminating repeated switches while preserving that additional effect.

A plain validated enum may be enough when the value has no varying behavior. Choose objects because they simplify observed operations, not because a string exists.

**Adaptation:** use an explicit allowed mapping for untrusted state names. The book's dynamic constant lookup is an illustrative convenience, not a validation strategy.

## 4.10 Wrap collaborators in Adapters

**When:** collaborators can fulfill one role but expose incompatible operations.

**How:** wrap the outlier at initialization or another entry point. Present the common interface to the rest of the object.

The source unifies array, file, socket, and IRC logging sinks under `<<`. The IRC wrapper translates `<<` into a bot event. The logger no longer switches on sink class for every message.

**Trade-off:** one wrapper and translation replace distributed conditionals. Preserve what the protocol promises about return values, side effects, and failures.

## 4.11 Use transparent adapters to gradually introduce abstraction

**When:** a legacy object already has many callers of its concrete interface, so a narrow adapter would break untouched code.

**How:** use a delegating wrapper, add the common operation, then migrate one caller at a time. The source uses `DelegateClass` from `delegate`. Audit type switches: delegation does not make every class identity check work automatically.

**Why:** compatibility gives the new abstraction a foothold without a simultaneous rewrite.

**Failure mode:** leaving every concrete operation exposed forever can preserve the coupling the adapter was meant to remove. Keep the migration grounded in actual callers.

## 4.12 Reject unworkable values with preconditions

**When:** an input has no sound interpretation and letting it enter creates inconsistent object state or delayed failure.

**How:** reject it wherever the invariant can be violated, before mutation. Route construction through the validated setter when later assignment is also supported.

The Employee example requires a valid hire date. Several methods otherwise invent different responses to a missing date: raise, use an arbitrary year, or change the biography. One invariant removes that disagreement.

A constructor check is insufficient if an unrestricted writer can later set nil. Fetching a required key is insufficient if the value itself can be invalid.

**Trade-off:** a precise type check can be justified for the domain invariant, while pervasive type checks in trusted work remain undesirable.

## 4.13 Use #fetch to assert the presence of Hash keys

**When:** a required key may legitimately contain false or nil.

**How:** use `fetch`; validate the returned value independently if needed. A block may raise a more useful missing-key error.

| Expression for `{enabled: false}` | Meaning |
|---|---|
| `h[:enabled]` | returns false; missing and explicit nil remain indistinguishable in the general case |
| `h.fetch(:enabled)` | returns false, proving the key was supplied |
| `h.fetch(:missing)` | raises KeyError |
| `h.fetch(:enabled) { true }` | preserves false |

The source's account-creation example uses false as a deliberate disabled-login flag. A truthiness-based precondition wrongly rejects it. Fetch corrects the presence test without replacing the caller's decision.

Array and ENV also offer fetch-style retrieval, with their own missing-entry behavior.

## 4.14 Use #fetch for defaults

**When:** an optional key should default only when absent.

**How:** provide the default in a block. The source prefers block defaults consistently to avoid future eager computation or unintended effects.

```ruby
def quiet_setting(options, &default)
  options.fetch(:quiet, &default)
end
```

If callers intentionally pass false, preserve it. If nil is unacceptable, reject or normalize it explicitly; fetch does not do that for you.

**Why:** the code distinguishes missing configuration from intentionally supplied values. A lazy block runs only when needed. A shared default proc is useful only when the same computed default actually recurs.

## 4.15 Document assumptions with assertions

**When:** an external response is undocumented, inconsistent, or likely to change.

**How:** state assumptions at first use: collection shape, required fields, accepted numeric format. Test sample responses and revise assumptions when failures expose misunderstanding. Retain the assertions as change detectors.

**Worked reasoning:** the banking example initially assumes integer cents. Inspecting a failure reveals decimal strings. Required-key fetch and stricter numeric conversion make that understanding executable instead of silently mapping an unfamiliar amount to zero.

**Adaptation:** its Float-times-100 example is about detecting format errors, not exact monetary arithmetic. Use the application's established exact representation and rounding policy for money.

Assertions are boundary documentation. They should not become repetitive checks in every downstream method.

## 4.16 Handle special cases with a Guard Clause

**When:** an unusual case should skip the whole method.

**How:** return early, preferably placing `return` prominently, and leave the ordinary body unindented. A quiet-mode check is a good example.

**Failure mode:** a guard returning nil breaks a collection-return contract. Choose the correct result at every exit. If both branches perform substantial normal work, a guard may not be the right representation.

## 4.17 Represent special cases as objects

**When:** a recurring special case requires coherent behavior in many callers.

**How:** provide another implementation of the same role. Start locally in one method if a global API migration would be too large. Keep ordinary and special implementations aligned through shared behavior tests.

The source's GuestUser supplies a name, denies roles, returns public listings, accepts a harmless activity update, and provides a session cart. Authentication remains an explicit predicate where the distinction matters. The purpose is not to erase every conditional; it is to locate special behavior consistently.

**Adaptation:** a guest object is truthy. Do not replace a framework authentication helper globally without auditing checks that rely on nil. Do not let a presentation convenience change authorization semantics.

## 4.18 Represent do-nothing cases as null objects

**When:** absence specifically means an interaction should do nothing, as with disabled optional logging.

**How:** implement the required interface with no-op commands and appropriate query results. Normalize the collaborator once rather than guarding each interaction.

A generic null can accept every message using `method_missing`. A black hole variant returns itself so chained operations also disappear. The source discusses both and warns about propagation: a leaked null may claim both draft and approved merely because both return the same truthy object.

**Failure modes:** swallowed typos, silent missing effects, truthy pseudo-predicates, and unintended propagation to callers. Ruby does not permit custom objects to become falsey in conditionals by overriding `nil?` or `!`.

Use a narrow explicit null when that suffices. Keep generic black holes within a deliberate boundary and restore a documented outward result. Do not confuse them with meaningful Special Case objects.

## 4.19 Substitute a benign value for nil

**When:** information is nonessential and a real known-good value is acceptable.

**How:** choose a domain-appropriate fallback during input gathering, then proceed normally.

The source uses a group's city location when an individual member's location cannot be resolved. The city still has meaningful map data; it is not a null location. This keeps optional location handling from dominating member rendering.

**Failure mode:** an arbitrary default can misrepresent required facts. The acceptability of the fallback is a product/domain decision, not just whether it avoids an exception.

## 4.20 Use symbols as placeholder objects

**When:** an optional collaborator is unnecessary for some paths but should produce a traceable failure if another path tries to use it.

**How:** default to a descriptive symbol, such as `:credentials_not_set`, rather than anonymous nil. An unexpected operation names the placeholder in its error, making its origin searchable.

This is a small diagnostic improvement, not a substitute for explicit validation when missing credentials are a normal user error. Symbols remain truthy and can support operations themselves; choose the representation knowing how it will be used.

**Adaptation:** the source logs URLs containing credential examples. Do not carry credentials into generated URLs or logs in real applications; that incidental example is unnecessary to the placeholder technique.

## 4.21 Bundle arguments into parameter objects

**When:** the same cohesive group of values travels through several methods.

**How:** introduce the domain concept, then move relevant validation and behavior toward it. A Point containing x/y can own serialization and cooperate with a map through `draw_on(map)`.

The source shows how starred points can specialize behavior and fuzzy points can decorate it. Composition lets a point be both starred and fuzzy without multiplying conditionals across drawing and persistence code.

**Why:** the object becomes a method magnet, revealing responsibilities that were previously scattered.

**Failure mode:** an arbitrary bag of unrelated options is not improved merely by becoming a class. Keep the concept cohesive and avoid building subtype combinations that have no caller.

## 4.22 Yield a parameter builder object

**When:** a useful internal object design has made client construction substantially awkward.

**How:** first consider yielding the actual parameter object for customization before use. Yield a builder only when customization must replace or wrap that object. The source's PointBuilder can install a FuzzyPoint decorator, then expose the resulting point for drawing.

Named setters make misspellings fail at their source, permit validation, and let callers inspect existing defaults. A delegating builder can hide class combinations behind a stable API.

**Trade-off:** the builder adds machinery and hides the origins of available methods. Document the interface. The source explicitly recognizes that this can be excessive for a simple API.

## 4.23 Receive policies instead of data

**When:** callers need different behavior for an edge case, and boolean flags are multiplying.

**How:** accept a named block or proc defining the policy. Supply a meaningful default so the work can invoke it without repeatedly asking whether it exists. Pass enough context, including the error, for the caller to decide.

The file-deletion example evolves from `ignore_errors` and `log_errors` flags to an error policy. The default raises; other policies log, ignore a particular expected failure, or choose another action.

**Failure modes:** catching more errors than intended, treating a failing callback as another operation failure, and accepting many procs for what should be separate responsibilities. Multiple policies are possible, but the author recommends reconsidering responsibility boundaries first.

## Worked example: normalize a logger option once

This reconstruction combines the source's false-valued logger default, null logger, and boundary normalization. It uses an in-memory log and has no network or filesystem effects.

```ruby
class SilentLog
  def info(message)
  end
end

class LineLog
  def initialize(lines)
    @lines = lines
  end

  def info(message)
    @lines << message
  end
end

class ReadingReporter
  def initialize(options = {})
    logger = options.fetch(:logger) { LineLog.new([]) }
    @logger = logger == false ? SilentLog.new : logger
  end

  def record(reading)
    @logger.info(reading)
  end
end
```

1. `fetch` distinguishes omission from explicit false, and creates the default lazily.
2. False is translated to a no-op implementation of the `info` role.
3. A caller-provided logger is retained.
4. `record` sends its message without another presence check.

The array is wrapped because arrays support `<<`, not `info`: an available object must actually fulfill the required role. Explicit nil still fails on use; this interface defines false, not nil, as disabled. A different nil policy must be deliberate.

## Key concepts and takeaways

- **Boundary:** a place where objects outside the trusted neighborhood become internal collaborators.
- **Invariant:** a property that must stay true after construction and subsequent mutations.
- **Normalization:** reducing accepted representations to a dependable internal form.
- **Special Case:** meaningful alternate behavior for a recurring situation.
- **Null Object:** the intentionally inactive implementation of a role.
- **Policy:** caller-supplied behavior for a decision the caller is qualified to make.

Choose semantics before syntax. Preserve false and nil when they are meaningful, reject them when they violate a contract, and substitute only when the replacement is honest. A single well-chosen boundary decision can remove dozens of downstream branches.

## Connects to

[Chapter 3](ch03-performing-work.md) defines the roles being prepared. [Chapter 5](ch05-delivering-results.md) applies similar care to values delivered to callers. [Chapter 6](ch06-handling-failure.md) combines checked methods with policies. [Chapter 7](ch07-refactoring-for-confidence.md) shows fetch and explicit-nil compatibility in legacy code.
