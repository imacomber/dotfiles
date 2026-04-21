# CLAUDE.md

This file defines how Claude should work with me on Ruby on Rails projects. Read it before doing anything else in this codebase.

---

## Ask First

If you are unsure of what I'm asking for or what outcome I want, **ask clarifying questions before proceeding**. A wrong assumption wastes more time than a quick question.

---

## Stack

- **Framework**: Ruby on Rails (always latest stable)
- **Testing**: RSpec, Capybara, FactoryBot, VCR
- **Frontend**: Hotwire, Turbo, Stimulus
- **Background Jobs**: Sidekiq
- **Auth**: Devise
- **Authorization**: Pundit
- **Style**: StandardRB
- **Database**: PostgreSQL
- **CI/CD**: GitHub Actions
- **Local Dev**: Docker via Colima

---

## Code Style

- Follow **StandardRB** — no exceptions unless there's a project-level `.rubocop.yml` override.
- Write code as if a fellow engineer will read it tomorrow. Clarity beats cleverness.
- **Comments** should be rare and purposeful: only explain logic that is genuinely non-obvious. Never comment code that speaks for itself.

---

## Architecture & Patterns

### Key Conventions

- Business logic in `app/models/` — never in controllers (create PORO models if logic doesn't belong in existing model class)
- Controllers call model objects, nothing else
- Jobs must be idempotent
- Hotwire-first — no JavaScript until Turbo genuinely can't do it
- Tests verify behavior, not implementation (see spec-agent for philosophy)

### Models & POROs

There are no service objects in this codebase. If you're reaching for a service object, reconsider:

- Does this belong on an existing model?
- Should this be a plain Ruby object (`PORO`) living in `app/models/`?

Keep business logic close to the domain it belongs to.

### Concerns & Modules

Both are welcome and encouraged when used well:

- Use modules to **share behavior** across multiple classes.
- Use concerns to **reduce clutter** in a large central model — even if that concern isn't shared with any other model. A well-named concern that groups related behavior makes a model significantly easier to read.

### Metaprogramming

Metaprogramming is a legitimate tool when it makes code genuinely cleaner and more readable. **Never use it to be clever.** If metaprogramming makes the code harder for another engineer to follow, it's the wrong choice.

---

## Agent Team

This project uses a specialized agent team. For any new feature or fix,
always invoke the **architect** agent first. It will coordinate all others.

```
architect        → orchestrates everything
├── data-agent   → models, migrations
├── api-agent    → controllers, routes
├── jobs-agent   → background workers, mailers
├── frontend-agent → views, Turbo, Stimulus
└── spec-agent   → RSpec (behavior-focused)
```

### Workflow

1. Describe the feature to the architect agent
2. Architect writes `.claude-docs/plan.md` with phased checklist
3. Specialist agents execute phases (parallel where safe via git worktrees)
4. Spec agent verifies each phase before it's marked complete
5. You review and merge

### Parallel Worktree Setup

For parallel execution of independent phases:

```bash
git worktree add ../$(basename $PWD)-data feature/<name>-data
git worktree add ../$(basename $PWD)-jobs feature/<name>-jobs
```

Run each agent in its own worktree terminal. Merge back to primary feature branch when green.

### Docs

- `.claude-docs/plan.md` — current feature plan with checkbox progress
- `.claude-docs/architecture.md` — system architecture overview (if present)
- `.claude-docs/decisions/` — ADRs for significant technical decisions

---

## Planning & Alternatives

During the planning phase, **show alternatives** rather than jumping to a single recommendation.

Each option should include:

- What it is and how it works in context
- Pros and cons (not generic — specific to this situation)
- A clear recommendation with your reasoning

This helps me make an informed decision rather than inheriting yours.

---

## Git & Workflow

### Commits

- Small, focused, and thematically coherent.
- Each commit should represent one logical unit of change.
- Write commit messages that describe _why_, not just _what_.

### Pull Requests

- PRs should be small and easy to review.
- A single feature may span multiple PRs — that's intentional. Ship the smallest chunk of value first.
- Different features should live on **separate Git worktrees** to avoid collisions and support parallel sub-agent work.

### Branch Strategy

Use Git worktrees for feature isolation. This is especially important when delegating work across multiple agents working concurrently.

---

## Voice & Collaboration

I work on a team. Anything we write together needs to sound like me — not like an AI assistant wrote it. My voice should come through clearly in:

- Code style and naming decisions
- PR descriptions and commit messages
- Any prose or documentation we produce

Match my register. If something reads like it was generated, rewrite it until it doesn't.
