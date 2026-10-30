# Chapter 6: Handling Failure

**Source:** printed pp. 251-263; sections 6.1-6.3.

## Core idea

Keep ordinary work readable while making failure policy explicit. The target is distracting inline begin/rescue/end blocks and repeated low-level status checks, not the elimination of error handling.

## 6.1 Prefer top-level rescue clause

**When:** a method contains an inline begin/rescue/end block and its recovery can coherently belong to the method.

**How:** use the method body's rescue syntax, often after extracting the risky operation into a method with a focused responsibility. The normal path appears above the rescue; exceptional scenarios appear below it.

**Why:** the reader can finish the main story before considering failure behavior. A helper that legitimately owns the rescue may also reveal a better responsibility boundary.

**Failure mode:** moving an inner rescue to the method level broadens what is protected. An exception from preparation, a caller callback, or later processing may now take a recovery path it previously could not. Extract the original protected work or retain the original scope if necessary.

The book motivates this visually; the scope warning is an adaptation safeguard. Readability does not justify returning a successful fallback for a defect.

## 6.2 Use checked methods for risky operations

**When:** a system or library operation has a known expected failure, with repeated or distracting handling.

**How:** encapsulate the operation and its specific failure in a small checked method. It can invoke a caller-supplied recovery policy; default propagation is often useful. Return the successful result unchanged.

The source wraps IO.popen and handles Errno::EPIPE via an error policy, letting the filter operation describe writing input, closing its write side, and reading output. The wrapper is a step toward an adapter when several interactions with the same external interface need a common boundary.

**Failure modes:** rescuing too broadly, forgetting the successful return value, losing a failure's identity, or swallowing an exception from arbitrary client code. A block-based wrapper protects everything executed inside the block, not only the library call visible at the top.

## 6.3 Use bouncer methods

**When:** failure is recorded as a status value rather than raised as an exception.

**How:** check that status in a clearly named method and raise a meaningful exception if it indicates failure. Call it at the point where the status belongs to the operation just completed. A block form can preserve the block's return value while performing the check afterward.

The source checks a child process's Process::Status after IO.popen finishes. It considers both a separate check and a wrapper; the author does not claim one is universally preferable.

**Why:** the main work need not contain repeated, opaque status-to-exception translations. The check remains visible in domain language.

**Failure modes:** checking stale global process status, replacing a successful block result with the checker result, or mistaking a signaled process for a normal numeric exit. Adaptation: prefer passing the relevant status explicitly when the surrounding process API makes it available.

## Reference table

| Situation | Technique | Semantics to preserve |
|---|---|---|
| One operation raises a known exception | Checked method | Exact rescued failures and fallback result |
| Whole method shares a recovery action | Method-level rescue | Protected scope and propagation |
| Operation reports failure as data | Bouncer | Correct status and meaningful raised error |
| Several external calls need adaptation | Adapter may become useful | Public role, resource ownership, failure contract |

## Worked example: a checked read with explicit policy

This reconstruction uses a missing file rather than spawning a shell command. There is no automatic suppression: omitting the policy raises the original missing-file error.

```ruby
def checked_read(path, on_missing = ->(error) { raise error })
  File.read(path)
rescue Errno::ENOENT => error
  on_missing.call(error)
end
```

1. A successful read returns its contents.
2. A missing file invokes the policy with the original error.
3. Other read failures propagate unchanged.
4. A failing policy propagates its own exception; the rescue body is not retried as protected work.

A caller deciding that missing *optional* content should mean an empty string can supply a policy returning `""`. A caller reading required configuration should normally preserve failure. Resource cleanup is handled by File.read; wrappers around open handles must preserve their own lifecycle.

## Worked example: converting status into an exception

```ruby
class ChildFailed < StandardError
end

def assert_child_succeeded(status)
  return if status.success?

  detail = if status.signaled?
    "signal #{status.termsig}"
  else
    "exit #{status.exitstatus}"
  end
  raise ChildFailed, "Child failed: #{detail}"
end
```

The important step is the translation from a known status to an explicit failure. This reconstructed helper handles signal termination as well as ordinary nonzero exit. It deliberately receives a status rather than looking up an unrelated later global value.

A caller can retain its own result, call this bouncer, and return the result. An alternative wrapper can store `result = yield`, check the operation's status, then return result. Choose whichever makes the lifecycle easier to see.

## Key concepts

- **Protected scope:** code whose exceptions a rescue may intercept.
- **Checked method:** an operation boundary that owns a known exception policy.
- **Bouncer method:** a focused check that turns invalid status/state into an exception.
- **Failure policy:** behavior chosen by the code that knows whether recovery is acceptable.
- **Propagation:** preserving failures for a caller rather than silently inventing success.

## Anti-patterns

- Rescuing Exception merely to simplify the shape of a method.
- Returning nil after every failure and forcing callers to diagnose its origin.
- Losing ensure-based cleanup while moving code.
- Adding an adapter hierarchy when a small checked helper is sufficient.
- Retrying or duplicating side effects because a callback error was misclassified as operation failure.

## Takeaways

1. Separate ordinary work from recovery, with behavior preserved.
2. Keep error translation close to the external operation that creates it.
3. Use named checks to make status failures understandable.
4. Prefer specific rescued errors and explicit recovery policies.

## Connects to

[Chapter 4, section 4.23](ch04-collecting-input.md) supplies caller policies. [Chapter 5](ch05-delivering-results.md) chooses outward failure representations. [Chapter 7](ch07-refactoring-for-confidence.md) refactors repeated parser recovery.
