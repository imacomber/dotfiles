# Pattern catalog

The 32 named input/result/failure patterns. Section 4.1 is background. See chapter files for examples and adaptation notes.

## Input: coerce

### 4.2 Use built-in conversion protocols
**When to use:** core representation required. **How:** request to_str/to_int/to_ary or an appropriate explicit conversion. **Trade-offs:** broad conversions are convenient but can hide invalid data; narrow ones impose a stronger contract.

### 4.3 Conditionally call conversion methods
**When to use:** ordinary inputs lack a contextual protocol. **How:** optionally call to_path or similar, then require the base representation. **Trade-offs:** flexible boundary; document the conversion and avoid per-operation capability checks.

### 4.4 Define your own conversion protocols
**When to use:** a core container has additional domain semantics. **How:** define to_coords or another meaningful protocol, then normalize and validate the result. **Trade-offs:** maintain the extension contract.

### 4.5 Define conversions to user-defined types
**When to use:** domain operations require a unit/value type. **How:** define to_meters or equivalent on compatible objects and return self for the target. **Trade-offs:** define precision and units.

### 4.6 Use built-in conversion functions
**When to use:** accept sensible variants of a core type. **How:** normalize with Integer(), Float(), or another chosen function. **Trade-offs:** each function accepts different forms.

### 4.7 Use the Array() conversion function to array-ify inputs
**When to use:** intentionally accept none, one, or many. **How:** Array(input), then operate on a collection. **Trade-offs:** nil becomes empty; hashes become pairs, not singleton records.

### 4.8 Define conversion functions
**When to use:** several public forms should become one internal domain type. **How:** centralize idempotent conversion and meaningful extension hooks. **Trade-offs:** avoid speculative or permissive formats.

### 4.9 Replace "string typing" with classes
**When to use:** repeated switches encode behavior in a primitive state. **How:** move behavior to domain objects and normalize names at entry. **Trade-offs:** types must simplify real variation.

### 4.10 Wrap collaborators in Adapters
**When to use:** one role has incompatible concrete interfaces. **How:** translate through a wrapper once at the boundary. **Trade-offs:** preserve result/error semantics.

### 4.11 Use transparent adapters to gradually introduce abstraction
**When to use:** untouched legacy callers still require concrete methods. **How:** delegate the old interface while adding the common role, migrating callers gradually. **Trade-offs:** temporary coupling remains; audit identity/type switches.

## Input: reject and default precisely

### 4.12 Reject unworkable values with preconditions
**When to use:** no honest conversion or substitute exists. **How:** reject before effects and at every state mutation that can violate the invariant. **Trade-offs:** stricter entry must match the promised contract.

### 4.13 Use #fetch to assert the presence of Hash keys
**When to use:** key presence matters independently of truthiness. **How:** fetch required keys; optionally customize the missing-key error. **Trade-offs:** nil/false remain unvalidated.

### 4.14 Use #fetch for defaults
**When to use:** only omission should trigger a default. **How:** fetch with a lazy block. **Trade-offs:** define nil/false policy separately; ordinary default arguments evaluate eagerly.

### 4.15 Document assumptions with assertions
**When to use:** uncertain external data. **How:** assert expected shape, fields, and formats at first use. **Trade-offs:** catch drift without redundant checks.

### 4.16 Handle special cases with a Guard Clause
**When to use:** an unusual case ends the entire method. **How:** return early with the correct result contract. **Trade-offs:** preserve the return contract.

## Input: substitute and organize

### 4.17 Represent special cases as objects
**When to use:** the same alternate case affects many operations. **How:** implement a shared role with meaningful alternate behavior. **Trade-offs:** synchronize contracts and audit truthiness changes.

### 4.18 Represent do-nothing cases as null objects
**When to use:** no interaction is the intended behavior. **How:** supply an inactive implementation once. **Trade-offs:** generic black holes hide mistakes and can leak; null objects remain truthy.

### 4.19 Substitute a benign value for nil
**When to use:** optional information admits an honest known-good fallback. **How:** substitute during input gathering. **Trade-offs:** simplification must not invent required facts.

### 4.20 Use symbols as placeholder objects
**When to use:** an optional value may become necessary on a later path. **How:** use a descriptive symbol default. **Trade-offs:** explicit validation may be clearer.

### 4.21 Bundle arguments into parameter objects
**When to use:** cohesive values recur together. **How:** make the domain concept explicit and move its behavior/validation toward it. **Trade-offs:** avoid unrelated option bags.

### 4.22 Yield a parameter builder object
**When to use:** constructing useful domain objects burdens callers. **How:** yield the parameter, or a builder when replacement/decorating is needed. **Trade-offs:** machinery and discoverability cost.

### 4.23 Receive policies instead of data
**When to use:** edge-case decisions vary and flags multiply. **How:** accept a named block/proc with a clear default. **Trade-offs:** many policies may reveal excessive responsibilities; keep exception scopes deliberate.

## Results

### 5.1 Write total functions
**When to use:** zero, one, or many results. **How:** return a collection on every successful path, including guards. **Trade-offs:** do not mask operational errors as empty results.

### 5.2 Call back instead of returning
**When to use:** action follows a successful change. **How:** invoke a callback with context on that event. **Trade-offs:** define callback count and propagation; this alone does not guarantee idempotency.

### 5.3 Represent failure with a benign value
**When to use:** nonessential output can be harmlessly empty. **How:** return a usable neutral value. **Trade-offs:** loses the distinction between absence and failure.

### 5.4 Represent failure with a special case object
**When to use:** missing query result has meaningful alternate behavior. **How:** return that role's Special Case. **Trade-offs:** change public truthiness only after auditing callers.

### 5.5 Return a status object
**When to use:** several outcomes need diagnostic detail. **How:** named predicates plus retained error/context. **Trade-offs:** more API; not necessary for every boolean command.

### 5.6 Yield a status object
**When to use:** event/batch outcomes fit callbacks. **How:** yield outcome-specific callback methods. **Trade-offs:** nesting and zero/many invocations must be documented; preserve client errors.

### 5.7 Signal early termination with throw
**When to use:** normal completion must cross intervening calls. **How:** paired catch/throw. **Trade-offs:** surprising nonlocal control; prefer local exits when sufficient.

## Failures

### 6.1 Prefer top-level rescue clause
**When to use:** one method coherently owns recovery. **How:** method-level rescue, extracting focused protected work as needed. **Trade-offs:** moving rescue can widen scope.

### 6.2 Use checked methods for risky operations
**When to use:** known library/system failure clutters callers. **How:** encapsulate it with a specific recovery policy. **Trade-offs:** preserve results, cleanup, and errors.

### 6.3 Use bouncer methods
**When to use:** status/state indicates failure without raising. **How:** named check raises a meaningful exception. **Trade-offs:** use correct status; retain results.
