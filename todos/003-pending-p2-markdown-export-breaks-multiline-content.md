---
status: pending
priority: p2
issue_id: "003"
tags: [code-review, markdown, export, quality]
dependencies: []
---

# Fix markdown table corruption for multiline trace fields

Markdown export currently escapes pipe characters but does not normalize newlines in table cells, which breaks table structure for multiline content.

## Problem Statement

Trace fields often contain multiline prompts, stack traces, or JSON. Without newline escaping/normalization, the generated markdown table becomes malformed and unusable.

## Findings

- `MarkdownFormatter` only escapes `|` (`lib/langfuse/cli/formatters/markdown_formatter.rb:49`).
- No handling for `\n`, `\r`, or long inline markdown content exists.
- Nested structures are converted to JSON strings (`lib/langfuse/cli/formatters/markdown_formatter.rb:41`), which can include escaped content and large blobs.
- Existing tests cover pipes but not multiline values (`spec/unit/formatters/markdown_formatter_spec.rb:91`).

## Proposed Solutions

### Option 1: Normalize newlines to `<br>` in markdown cells

**Approach:** Replace `\r?\n` with `<br>` in cell values after escaping pipes.

**Pros:**
- Keeps valid single-row table semantics.
- Minimal implementation change.

**Cons:**
- Some markdown renderers treat HTML differently.

**Effort:** Small

**Risk:** Low

---

### Option 2: Switch markdown format for nested/large values to fenced JSON blocks

**Approach:** For problematic fields, output compact summary in table plus linked or appended fenced block.

**Pros:**
- Preserves readability for complex content.
- More robust than giant one-line cells.

**Cons:**
- More complex output format.

**Effort:** Medium

**Risk:** Medium

## Recommended Action


## Technical Details

**Affected files:**
- `lib/langfuse/cli/formatters/markdown_formatter.rb:27`
- `spec/unit/formatters/markdown_formatter_spec.rb:98`

**Related components:**
- Markdown export path used by all commands

**Database changes (if any):**
- No

## Resources

- Markdown formatter implementation: `lib/langfuse/cli/formatters/markdown_formatter.rb`
- Existing tests: `spec/unit/formatters/markdown_formatter_spec.rb`

## Acceptance Criteria

- [ ] Markdown export preserves valid table structure with multiline fields.
- [ ] Unit tests include values with newline and carriage return characters.
- [ ] Export behavior for nested JSON is documented.

## Work Log

### 2026-02-10 - Code Review Discovery

**By:** Codex

**Actions:**
- Audited markdown escaping behavior.
- Compared implementation against common trace payload characteristics.

**Learnings:**
- Pipe escaping alone is insufficient for markdown table integrity.

## Notes

- Priority is P2 because this is correctness and usability, not direct data loss.
