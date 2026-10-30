---
name: confident-ruby
description: "Apply Avdi Grimm's Confident Ruby when writing or reviewing Ruby methods: narrative flow, duck typing, conversion protocols, Hash#fetch, preconditions, special case and null objects, predictable results, policies, and focused failure handling. Also use for studying or looking up the book's chapters and patterns."
---

# Confident Ruby

**Author:** Avdi Grimm. **Source:** supplied PDF, 296 physical pages; copyright 2013, foreword dated 2014. **Chapters:** 8. **Generated:** 2026-10-30.

Write methods whose purpose is easy to follow. Establish dependable collaborators at the boundary, perform the work using domain messages, and provide results that let callers do the same.

## How to use

- For a review, identify the method's central task, classify distracting checks, then select the smallest applicable pattern.
- For a topic or pattern, read the relevant chapter below before giving detailed advice. Chapter 4 has named sections for all 23 source sections.
- For a chapter request such as `ch05`, read that chapter file.
- Use [cheatsheet.md](cheatsheet.md) to decide between alternatives, [patterns.md](patterns.md) for the complete pattern catalog, and [glossary.md](glossary.md) for terminology.
- Distinguish the author's guidance from the adaptation notes in these files. Follow the current project's conventions when applying an idea.

## Core frameworks

### The four parts of a method

Organize a method into coherent phases: **collecting input, performing work, delivering output, handling failures**. Not every method has all four. Diagnostics and cleanup may also appear. Input includes arguments, instance state, constants, collaborators' responses, files, environment settings, and time.

Start a review by identifying each line's role. Frequent jumps between input gathering, nil checks, work, and rescue logic indicate a confused narrative. Collect and normalize inputs before the main work; put exceptional handling where it can be understood separately. Preserve resource cleanup and the actual scope of exceptions when rearranging code.

### Sending a strong message

1. Identify the messages needed to perform the task in the problem's language.
2. Identify the roles that should receive those messages.
3. Bridge the available objects to those roles.

A role is a set of responsibilities, not a particular class. A method that needs an output sink can send `<<` to a file, an array, or an adapter. Keep work at one level of abstraction. Do not let incidental library details dictate the domain story; equally, do not invent classes when existing objects already play the role.

### Guard the borders, not the hinterlands

At a public API or subsystem boundary, choose deliberately among **coerce, reject, substitute**:

- **Coerce** when an incoming value has a meaningful conversion to the required role.
- **Reject** when no sound interpretation exists, especially before effects can occur.
- **Substitute** when absence has a legitimate, known meaning: a guest user, a disabled logger, or an optional empty result.

Inside that boundary, send the required messages confidently. Repeating class tests and nil checks in every helper distributes uncertainty instead of resolving it. Assertions remain useful at poorly documented external boundaries, even when exact type checks would be excessive inside trusted code.

### Choose conversions for their semantics

`to_str`, `to_int`, and `to_ary` ask for objects that are string-like, integer-like, and array-like. `to_s`, `to_i`, and `to_a` permit broader representations. `to_i` can silently turn invalid text into zero; a conversion is not automatically validation.

Use `Integer(value)` or `Float(value)` when parsing should reject nonsense; they still have conversion-specific behavior, so choose intentionally. Use `Array(value)` for a documented one-or-many interface: nil becomes `[]`, a scalar becomes one element, and an array stays an array. A hash becomes key/value pairs, which may be wrong for a domain record.

Allow optional `to_path` or domain conversions at the boundary, then require the resulting representation. A custom conversion function should be safe to apply repeatedly and should return the already normalized object unchanged when appropriate. Document the accepted forms.

### Use fetch to express presence and defaults

`options.fetch(:key)` distinguishes a missing key from a present key containing `false` or `nil`. It checks presence, not value validity. `options.fetch(:key) { default }` applies a default only when the key is absent and computes it lazily. `options[:key] || default` instead replaces both false and nil.

Prefer the block form for computed defaults. Defaults passed as ordinary arguments are evaluated even when unused. Normalize any intentional flag, such as a false logger option, into a usable collaborator before the work begins.

### Give special cases an honest representation

Use a **Guard Clause** when an unusual case finishes the entire method. Use a **Special Case object** when the same exceptional situation recurs across many operations. Use a **Null Object** when the intended behavior is to do nothing. A guest user has meaningful behavior; it is more than a null user.

A benign value is a real, acceptable fallback for nonessential information. Do not replace required facts with arbitrary defaults. A symbolic placeholder can improve the provenance of an eventual error when an optional value becomes necessary later.

Keep alternate objects' contracts aligned with the ordinary objects. Ruby null objects remain truthy. Generic black hole null objects can spread silently and hide defects; use a small explicit interface when it suffices.

### Be kind to callers

If a query naturally returns multiple results, keep the result shape consistent for zero, one, and many, including early returns. The book calls this **Write total functions**, using a practical meaning narrower than mathematical totality.

When a command's completion should trigger work, consider a success callback. For several meaningful outcomes, use a status object that retains error detail; yield it when callback or batch semantics improve the interface. Boolean or symbolic outcomes may be sufficient for smaller APIs. Command-query separation is a design aid, not a reason to impose a complex callback API.

Use `catch`/`throw` sparingly for intentional, non-error termination across intervening calls. Exceptions represent failures; throw needs a matching catch.

### Isolate failure handling without losing failures

Prefer a method-level rescue when the whole method legitimately shares one recovery action. Extract a **checked method** to translate a known library exception into the intended policy. Use a **bouncer method** to turn an error status into a meaningful exception.

These techniques move handling; they do not justify deleting it. Keep rescued exceptions specific. Adaptation: a rescue covering a callback may accidentally reinterpret a client bug as an operation failure; keep the two scopes separate when that distinction matters.

### Let patterns follow evidence

Repeated switches on the same state can suggest domain classes. Repeated argument bundles can suggest a parameter object that attracts behavior. An adapter unifies interfaces; a transparent adapter supports gradual migration. A builder is useful only when constructing those objects has made a substantial API awkward. Multiple independent policy procs can indicate too many responsibilities.

## Chapter index

Numbers follow the PDF, including the foreword and closing chapter. Page references in chapter files use printed book pages; they differ from PDF viewer page numbers.

| Chapter | Title | Main material |
|---|---|---|
| [ch01](chapters/ch01-foreword.md) | Foreword | Purpose and method-level clarity; Sandi Metz |
| [ch02](chapters/ch02-introduction.md) | Introduction | Narrative flow; four parts of a method |
| [ch03](chapters/ch03-performing-work.md) | Performing Work | Messages, roles, duck typing |
| [ch04](chapters/ch04-collecting-input.md) | Collecting Input | All 23 sections: conversions through caller policies |
| [ch05](chapters/ch05-delivering-results.md) | Delivering Results | All 7 result patterns; collections, callbacks, status, throw |
| [ch06](chapters/ch06-handling-failure.md) | Handling Failure | All 3 failure patterns; rescue, checked and bouncer methods |
| [ch07](chapters/ch07-refactoring-for-confidence.md) | Refactoring for Confidence | MetricFu and Stringer; incremental changes and caller compatibility |
| [ch08](chapters/ch08-parting-words.md) | Parting Words | Recognizing accumulated uncertainty; choosing alternatives |

## Topic index

| Topic | Read |
|---|---|
| Adapters; transparent adapters; DelegateClass | ch04 sections 4.10-4.11 |
| Array(); one-or-many input | ch04 section 4.7; ch05 section 5.1 |
| Assertions; external data assumptions | ch04 section 4.15 |
| Benign values | ch04 section 4.19; ch05 section 5.3 |
| Black hole null objects; truthiness | ch04 section 4.18 |
| Bouncer methods; process status | ch06 section 6.3 |
| Builders; parameter customization | ch04 section 4.22 |
| Callbacks; command-query separation; idempotent imports | ch05 sections 5.2, 5.5-5.6 |
| catch/throw; early nonlocal termination | ch05 section 5.7 |
| Checked methods; failure policy | ch06 section 6.2 |
| Conversion functions; idempotent normalization | ch04 sections 4.6-4.8 |
| Conversion protocols; to_str/to_s; to_int/to_i; to_path | ch04 sections 4.2-4.5 |
| Duck typing; messages; roles; MacGyver methods | ch03 |
| fetch; required keys; nil/false; lazy defaults | ch04 sections 4.13-4.14; ch07 section 7.1 |
| Guard clauses | ch04 section 4.16; ch05 section 5.1 |
| Invariants; preconditions | ch04 section 4.12 |
| Method narrative; four phases | ch02; ch03 |
| Parameter objects; decorators; double dispatch | ch04 section 4.21 |
| Policies instead of flags; blocks and procs | ch04 section 4.23; ch06 section 6.2 |
| Refactoring; explicit nil callers; caching | ch07 |
| Rescue scope; narrow exceptions | ch06; ch07 section 7.2 |
| Special Case; GuestUser | ch04 section 4.17; ch05 section 5.4 |
| Status objects; return versus yield | ch05 sections 5.5-5.6 |
| String typing; repeated switches; state objects | ch04 section 4.9 |
| Symbolic placeholders | ch04 section 4.20 |
| Total functions; stable return shape | ch05 section 5.1 |

## Scope and provenance

Personal study and coding reference synthesized from the user-supplied book, not a replacement for it. The PDF was extracted with `pdftotext` because Docling was unavailable. Diagrams were not interpreted. Examples here are compact reconstructions, not verbatim listings; adaptation notes flag corrections and extra cautions. No contemporary third-party library API compatibility is claimed.


### Source record

- Supplied file: confident-ruby.pdf; 1,060,786 bytes.
- SHA-256: eb7696856eb3d4f279e8fc75450ce9f3cb728ea78a62d6ce545cb449c094a6a8.
- Extraction: requested technical mode; actual pdftotext fallback. About 41,667 words / 55,556 estimated source tokens, including front/back matter.
- Converter: book-to-skill, installed from https://github.com/virgiliojr94/book-to-skill.
- Coverage: eight numbered chapters; all 23 input sections, 7 result patterns, and 3 failure patterns. Section 4.1 is background, leaving 32 named input/result/failure patterns.
- Preface acknowledgments and the font-license colophon introduce no coding patterns and are not separate references. Purchaser information and raw book text are not bundled.
- The text extractor does not give a reliable count of omitted PDF visuals; no claim of zero omitted images is made.
- Worked reconstructions do not provide production transaction, concurrency, authorization, retry, exact-money, or delivery guarantees.
- Personal local conversion only; no publication or remote upload.
