# Appendix B: An incomplete tour of Ruby's standard exceptions

Source: printed pages 94–102. The source's hierarchy and operating-system details describe its 2011 environment; the table below is a selective modern-oriented guide, not a frozen reproduction of that hierarchy.

## Core idea

Choose rescue scope from the actual inheritance tree. Similar names do not imply the same parent, and StandardError deliberately excludes several process, runtime, and script-level conditions.

## Selected families

| Family | Meaning and handling implication |
|---|---|
| Exception | Root of exception hierarchy; catching it is much broader than ordinary application recovery |
| StandardError | Default family selected by bare rescue |
| RuntimeError | General runtime failure; also the usual type from raising a message |
| ArgumentError | A method received an unsuitable argument; often caller misuse |
| TypeError | An operation received an incompatible type |
| RangeError | Value outside a representable or permitted range; inspect the concrete operation |
| IndexError | Invalid indexing/lookup family; includes KeyError and StopIteration in the checked runtime |
| NameError | Name resolution failure; includes NoMethodError |
| IOError | IO operation/protocol failure; includes EOFError |
| SystemCallError | Operating-system call failure; concrete Errno classes descend here |
| ScriptError | Script/load/syntax family outside StandardError; includes LoadError, SyntaxError, NotImplementedError |
| SignalException | Signal-related family outside StandardError; Interrupt descends here |
| SystemExit | Requested process exit; outside StandardError |
| NoMemoryError | Allocation exhaustion; outside StandardError; do not simulate by exhausting the machine |
| SystemStackError | Stack exhaustion; outside StandardError |

Use [Ruby 3.4's Exception hierarchy](https://docs.ruby-lang.org/en/3.4/Exception.html) to inspect the classes relevant to a real rescue. The book calls its tour incomplete; do not treat this table as a full standard-library or platform inventory.

## Important distinctions

### IOError and SystemCallError

A failure while working with a file can be an IOError, an Errno subclass, an argument error, or something else. SystemCallError is not an IOError subclass. Rescuing IOError therefore does not cover every filesystem failure. Rescue the documented concrete failures for the operation rather than assuming all IO-related events share one ancestor.

Errno names and numeric codes vary with the operating system. The source's Ubuntu table is historical; do not copy its numeric mapping into portable logic. Prefer named classes or documented error attributes.

### NotImplementedError

NotImplementedError is below ScriptError, so a bare rescue does not catch it. Its location is easy to overlook. Do not choose it casually for ordinary application “TODO” failures that callers expect to catch as StandardError. If designing an application-level unsupported-operation contract, select an error family that matches intended handling.

### StopIteration and EOFError

These can represent normal completion in APIs that define them that way. The class alone does not make the event a defect. Conversely, premature exhaustion during a promised fixed-length read may indicate failure. Let the contract decide.

### Signal and termination classes

Catching Exception may capture Interrupt or SystemExit and prevent expected interruption or shutdown. A broad boundary needs an explicit propagation policy. Do not intentionally create resource exhaustion to prove that a rescue matches NoMemoryError; inspect ancestry instead.

## Historical corrections

- The book discusses SecurityError in connection with `$SAFE`. Ruby 3.0 removed the special `$SAFE` feature; it is not a modern sandbox mechanism. See the [Ruby 3.0 release notes](https://www.ruby-lang.org/en/news/2020/12/25/ruby-3-0-0-released/).
- Timeout inheritance differed between source-era Ruby releases. In the checked Ruby 3.4 environment, Timeout::Error is a RuntimeError descendant. Do not infer it from an old hierarchy diagram.
- A timeout exception's inheritance does not make arbitrary interruption safe. Review what state can be left halfway through a protected operation. The standard library also documents details of Timeout's internal exception handling; a blanket rescue is not a cancellation design. See [Ruby 3.4 Timeout](https://docs.ruby-lang.org/en/3.4/Timeout.html).
- Built-in exception causes and default thread reporting also changed since publication; see [lifecycle](ch03-exception-lifecycle.md).

## Worked inspection

This read-only snippet checks relationships without triggering real failures:

```ruby
require "timeout"

book_exception_relationships = {
  key_error_is_standard: KeyError < StandardError,
  eof_is_io: EOFError < IOError,
  system_call_is_io: !!(SystemCallError < IOError),
  not_implemented_is_standard: !!(NotImplementedError < StandardError),
  interrupt_is_standard: !!(Interrupt < StandardError),
  timeout_is_runtime: Timeout::Error < RuntimeError
}
```

The expected values on the checked runtime are true, true, false, false, false, true. Inspecting loaded classes through ObjectSpace can show more of the current tree, but only classes loaded in that process are visible. Loading a library can add its error types.

## Takeaways

Bare rescue means StandardError, not “every ordinary-sounding error.” Inspect ancestry and operation contracts, keep OS-specific assumptions out of portable logic, and treat source-era security and timeout behavior as historical.
