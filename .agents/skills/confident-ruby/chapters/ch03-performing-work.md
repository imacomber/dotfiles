# Chapter 3: Performing Work

**Source:** printed pp. 19-29; section 3.1, Sending a strong message.

## Core idea

Design the main work in terms of domain messages and the roles that receive them. Then arrange for available objects to play those roles, keeping infrastructure detail out of the central story.

## Sending a strong message

1. List the steps needed to accomplish the task, in domain language.
2. Name the messages corresponding to those steps.
3. Group the receiving responsibilities into roles.
4. Write the work using those messages and roles.
5. Bridge from the concrete system to the roles, using input collection, conversion, adapters, or smaller collaborators as necessary.

A role can have several implementations. An object can play more than one role. Identifying a role does not automatically require a new class.

**Why it works:** a method can express its purpose at one level of abstraction. It does not keep asking whether its collaborators are qualified to do their jobs.

**Failure mode:** inventing a perfectly abstract vocabulary without connecting it to real objects creates indirection. The final bridging step is essential.

## Worked example: importing legacy purchases

The source develops an importer from a six-step task: parse old records, identify a customer, identify a product, attach the purchase, notify the customer, and log success.

| Message | Role |
|---|---|
| parse records | legacy-data parser |
| iterate | purchase list |
| supply email and product reference | purchase record |
| find or create customer | customer list |
| find or create product | inventory |
| add purchase and notify | customer |
| record success | importer itself |

This reconstruction keeps the importer's orchestration separate from lookup and parsing detail:

```ruby
class PurchaseImporter
  def initialize(parser, customers, inventory, log)
    @parser, @customers, @inventory, @log = parser, customers, inventory, log
  end

  def import(data)
    @parser.parse(data).each do |record|
      customer = @customers.obtain(record.email)
      product = @inventory.obtain(record.product_id)
      customer.add_purchase(product)
      customer.notify_available(product)
      @log.info(record.id)
    end
  end
end
```

The example establishes a message vocabulary; it is not a production import design. Persistence, transaction boundaries, delivery guarantees, and duplicate prevention require application-specific decisions. Chapter 5 discusses redundant imports and outcome notifications.

## Avoiding the MacGyver method

A MacGyver method's story is dominated by the tools already at hand: raw CSV options, ORM queries, low-level record fields, or logger-presence tests. Start by asking what needs to happen, rather than assuming existing library messages are the only possible vocabulary.

Then compare that vocabulary with what the system already offers. Often an existing helper or model already fulfills the desired role. Use it instead of creating another layer.

## Talk like a duck

A duck type is a behavioral role. Sending the required message is the point; checking `is_a?`, `respond_to?`, and nil before each ordinary operation undermines the simplification.

The book identifies two failures:

- Failing to decide what kind of duck is actually needed: the message vocabulary remains incidental.
- Giving up early: repeating runtime checks rather than ensuring suitable collaborators reach the work.

Repeated switches on one attribute can be indirect type switching. Several objects may be trying to share one representation while having genuinely different responsibilities.

## Key concepts

- **Message:** an operation requested of an object.
- **Role:** a related set of responsibilities, independent of a specific class.
- **Duck typing:** relying on an agreed behavioral protocol.
- **Abstraction level:** the granularity of detail at which a method tells its story.
- **Switch Statements Smell:** repeated decisions on the same type or state attribute.

## Anti-patterns

- Interleaving raw parsing details with high-level purchase operations.
- Adding a new class for every named role without checking existing collaborators.
- Replacing nil checks with safe navigation everywhere and declaring the role problem solved. This is an adaptation observation; the book predates that syntax.
- Treating boundary conversion checks as forbidden: chapter 4 explicitly allows them where they make the interface usable.

## Takeaways

1. Name the work, then identify receivers, then connect concrete objects.
2. Keep uncertainty out of the main message sequence by resolving it at a meaningful boundary.
3. Use repeated switches as evidence to investigate, not an automatic command to build a hierarchy.

## Connects to

[Chapter 4](ch04-collecting-input.md), especially adapters, conversion protocols, and special case objects, supplies the bridging techniques. [Chapter 7](ch07-refactoring-for-confidence.md) shows compromises needed in existing systems.
