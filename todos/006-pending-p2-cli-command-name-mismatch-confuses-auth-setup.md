---
status: pending
priority: p2
issue_id: "006"
tags: [code-review, docs, auth, ux]
dependencies: []
---

# Align command references with actual executable name

Several user-facing messages instruct `langfuse ...` commands, but the gem executable is `lf`. This causes setup and auth troubleshooting confusion.

## Problem Statement

Users following built-in guidance can run a non-existent command and assume config/auth is broken. This directly harms onboarding and supportability.

## Findings

- Gem executable is `lf` (`lf-cli.gemspec:22`).
- Config setup success message suggests `langfuse traces list` (`lib/langfuse/cli/commands/config.rb:88`).
- Command error guidance suggests `langfuse config setup` in multiple command classes (`lib/langfuse/cli/commands/traces.rb:86`, similar in sessions/observations/scores/metrics).
- Long descriptions also use `langfuse` examples in several commands.

## Proposed Solutions

### Option 1: Standardize on `lf` everywhere

**Approach:** Replace all `langfuse` command examples/messages with `lf`.

**Pros:**
- Removes ambiguity.
- Immediate user impact.

**Cons:**
- Potential mismatch if alternate binary exists in future.

**Effort:** Small

**Risk:** Low

---

### Option 2: Support dual aliases and document both

**Approach:** Keep `lf` primary but add optional `langfuse` alias executable.

**Pros:**
- More user-friendly.
- Reduces migration friction.

**Cons:**
- Packaging and maintenance overhead.

**Effort:** Medium

**Risk:** Low-Medium

## Recommended Action


## Technical Details

**Affected files:**
- `lf-cli.gemspec:22`
- `lib/langfuse/cli/commands/config.rb:88`
- `lib/langfuse/cli/commands/traces.rb:86`
- `lib/langfuse/cli/commands/sessions.rb:46`
- `lib/langfuse/cli/commands/observations.rb:82`
- `lib/langfuse/cli/commands/scores.rb:46`
- `lib/langfuse/cli/commands/metrics.rb:94`

**Related components:**
- CLI onboarding UX
- Authentication setup guidance

**Database changes (if any):**
- No

## Resources

- Gemspec executable declaration: `lf-cli.gemspec`
- Command docs and guidance messages in command classes

## Acceptance Criteria

- [ ] All in-product guidance uses the actual executable consistently.
- [ ] README examples align with executable naming strategy.
- [ ] If dual aliases are adopted, tests validate both entrypoints.

## Work Log

### 2026-02-10 - Code Review Discovery

**By:** Codex

**Actions:**
- Cross-checked executable declaration against command guidance.
- Enumerated mismatched references in command classes.

**Learnings:**
- Setup messaging inconsistencies can be mistaken for auth failures.

## Notes

- This directly impacts first-run experience and support load.
