# What is a failure?

Source: printed pages 15–17.

## Core idea

Define failure against the operation's purpose and contract. An exception is a mechanism for signaling an abnormal condition; it does not by itself identify a programming defect or dictate the right recovery.

## Definitions

| Term in the book | Meaning | Engineering consequence |
|---|---|---|
| Error | Defect in an implementation | Correct the code or its assumptions; retry alone rarely cures it |
| Failure | Inability to fulfill a purpose | Identify the promise that cannot be delivered |
| Exception | Abnormal condition encountered during execution | Choose an appropriate signal and response |

These terms describe related events at different levels. A remote resource can fail without a local programming error. A programming error can remain latent until a particular input exposes it. A normally raised EOF exception can be routine for one consumer and a failure for another.

## Design by Contract

Describe three things before choosing an exception:

- **Preconditions:** requirements the caller must satisfy before invocation.
- **Postconditions:** result and effects promised when the method completes successfully.
- **Invariant:** conditions that keep the object's state internally consistent across public operations.

A method may fail because its caller violates a precondition, its implementation cannot deliver the postcondition, or it cannot preserve the invariant. Locate the responsibility before attaching a rescue policy.

An invariant is not synonymous with every business validation. A draft invoice may lack required submission fields yet remain a consistent, usable draft. In contrast, an invoice total that disagrees with its own line items can violate an internal invariant. Invalid business data can be represented deliberately; corrupted internal relationships cannot be treated as an ordinary draft without changing the contract.

## Worked example: debit without corrupting the account

**Reconstruction:** the book's contract reasoning applied to a small object. This example chooses ArgumentError for an invalid request and a domain error for insufficient funds. A different caller may prefer a normal negative result for insufficient funds.

```ruby
class BookAccount
  class InsufficientFunds < StandardError; end

  attr_reader :balance

  def initialize(balance)
    fail ArgumentError, "balance must be a nonnegative integer" unless
      balance.is_a?(Integer) && balance >= 0

    @balance = balance
  end

  def debit(amount)
    fail ArgumentError, "amount must be a positive integer" unless
      amount.is_a?(Integer) && amount > 0
    fail InsufficientFunds, "insufficient funds" if amount > balance

    @balance -= amount
  end
end
```

The invariant is a nonnegative integer balance. The precondition is a positive integer amount. Success reduces the balance by exactly that amount. A rejected debit leaves the balance unchanged because the checks precede mutation.

This does not model concurrency, persistence, currencies, or distributed payments. Its purpose is to make the contract visible, not to provide a banking implementation.

## Reasons for failure

Distinguish defects, broken caller assumptions, environmental limits, unavailable resources, and expected domain rejection. The source's larger point is that failures have different origins and therefore need different policies. For example:

| Event | Contract question | Plausible response |
|---|---|---|
| Bad argument type | Was the caller required to supply a particular type? | Reject at the boundary with a useful diagnostic |
| Missing optional configuration | Is absence a supported state? | Return the documented default |
| Missing required configuration | Can the operation fulfill its promise without it? | Fail before partial work begins |
| Unavailable dependency | Can the caller wait, retry, or degrade? | Propagate enough information for that decision |
| Broken internal relationship | Is usable state still trustworthy? | Preserve evidence and prevent misleading continuation |

The same low-level error can support different rows. A missing file is harmless when discovering optional overrides and serious when opening the only copy of required input.

## Why this works

Contract reasoning separates evidence from policy. It prevents a broad low-level class such as IOError from becoming a universal instruction to retry or ignore. It also gives tests something meaningful to assert: after a failed debit, the balance still satisfies the invariant and has not changed.

## Anti-patterns

- Calling every negative answer a failure: this turns ordinary work into exception-driven control flow.
- Rescuing first and defining success later: the caller may receive a normal return after the promised effect never happened.
- Confusing consistency with validity: rejecting every incomplete object can erase useful intermediate states, while accepting inconsistent state can hide corruption.
- Testing only the exception class: also verify the state and effects promised on failure.

## Takeaways and connections

Define the promise, identify responsibility, and only then choose the signal. Continue with [strategy](ch06-failure-handling-strategy.md) for expected outcomes and error categories, and [exception testing](appendix-a-exception-testing.md) for checking state under interruption.
