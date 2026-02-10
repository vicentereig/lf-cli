---
status: pending
priority: p1
issue_id: "002"
tags: [code-review, performance, ux, traces]
dependencies: []
---

# Make large trace rendering safe by default

`table` is the default output format, but it is unsafe for very large trace payload fields because it attempts full-width rendering of massive strings.

## Problem Statement

The default mode should not degrade into unreadable output or high memory pressure for normal `traces get` usage. Today, large payloads can break terminal usability and destabilize the process.

## Findings

- Global default format is `table` (`lib/langfuse/cli.rb:31`).
- `traces get` returns full trace and immediately formats it (`lib/langfuse/cli/commands/traces.rb:71`, `lib/langfuse/cli/commands/traces.rb:143`).
- `TableFormatter` stringifies nested fields and builds full table rows in memory (`lib/langfuse/cli/formatters/table_formatter.rb:17`, `lib/langfuse/cli/formatters/table_formatter.rb:22`).
- No truncation, field allowlist, or large-field redaction exists.

## Proposed Solutions

### Option 1: Change default format for detail commands to JSON

**Approach:** Keep list commands on table; set `get/show` commands to JSON by default.

**Pros:**
- Safer default for large payloads.
- Better scriptability.

**Cons:**
- Behavior inconsistency between command families.

**Effort:** Small

**Risk:** Low

---

### Option 2: Keep table default, auto-truncate long fields

**Approach:** Truncate large cell values (for example 2KB) and show `[truncated]`.

**Pros:**
- Preserves current UX style.
- Easy to scan in terminal.

**Cons:**
- Loses full fidelity unless user switches format.

**Effort:** Medium

**Risk:** Low

---

### Option 3: Add explicit `--full` flag for unbounded rendering

**Approach:** Default to safe truncation; require `--full` to render full cells.

**Pros:**
- Safe by default and explicit for risky behavior.
- Backward-compatible path for power users.

**Cons:**
- Slightly more CLI complexity.

**Effort:** Medium

**Risk:** Low

## Recommended Action


## Technical Details

**Affected files:**
- `lib/langfuse/cli.rb:27`
- `lib/langfuse/cli/commands/traces.rb:68`
- `lib/langfuse/cli/formatters/table_formatter.rb:7`

**Related components:**
- Global CLI option defaults
- Human-readable output formatting

**Database changes (if any):**
- No

## Resources

- README default format docs: `README.md:194`
- Table formatter tests: `spec/unit/formatters/table_formatter_spec.rb`

## Acceptance Criteria

- [ ] Large trace detail command is safe by default (no unbounded cell rendering).
- [ ] Clear user-visible path exists for full untruncated output.
- [ ] Tests verify truncation/default behavior for large fields.
- [ ] README documents default safety behavior and override flag.

## Work Log

### 2026-02-10 - Code Review Discovery

**By:** Codex

**Actions:**
- Reviewed default output selection and detail command flow.
- Verified no table-mode guardrails for large values.

**Learnings:**
- Current defaults bias toward high-risk rendering path for huge payloads.

## Notes

- This issue directly matches user-reported instability concerns.
