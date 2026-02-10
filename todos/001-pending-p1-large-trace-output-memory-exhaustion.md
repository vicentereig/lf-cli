---
status: pending
priority: p1
issue_id: "001"
tags: [code-review, performance, reliability, export]
dependencies: []
---

# Prevent memory exhaustion on large trace exports

The CLI materializes full payloads and full formatted output strings in memory. For large traces (10MB, 20MB, 40MB+), this creates multiple copies and can trigger high memory usage or process crashes.

## Problem Statement

Large trace exports are not memory-safe. The code builds large in-memory structures during fetch, formatting, and write. This is risky for the exact workloads you called out.

## Findings

- `Client#paginate` accumulates all records in `all_results` before returning (`lib/langfuse/cli/client.rb:139`, `lib/langfuse/cli/client.rb:148`).
- JSON output always uses `JSON.pretty_generate`, allocating a full output string (`lib/langfuse/cli/commands/traces.rb:134`, same pattern in sessions/observations/scores/metrics).
- All command outputs call `File.write` with a fully built `formatted` string (`lib/langfuse/cli/commands/traces.rb:121`, similar in other commands).
- Markdown formatter builds an array of full lines and joins at the end (`lib/langfuse/cli/formatters/markdown_formatter.rb:17`, `lib/langfuse/cli/formatters/markdown_formatter.rb:31`).
- Local synthetic benchmarks showed output size scales linearly into tens of MB with no safeguards.

## Proposed Solutions

### Option 1: Add streaming output pipeline

**Approach:** Stream records directly to IO for JSON/CSV/Markdown, avoiding full-string materialization.

**Pros:**
- Handles very large payloads safely.
- Lowers peak memory dramatically.

**Cons:**
- Requires formatter API redesign.
- More complex code paths.

**Effort:** Large

**Risk:** Medium

---

### Option 2: Keep current formatters, add hard limits and guardrails

**Approach:** Add `--max-cell-bytes`, `--max-output-bytes`, and fail-fast warnings when limits are exceeded.

**Pros:**
- Fast to ship.
- Prevents worst-case crashes.

**Cons:**
- Still non-streaming.
- Users may get truncated output.

**Effort:** Medium

**Risk:** Low

---

### Option 3: Hybrid approach

**Approach:** Stream JSON/CSV first, keep table/markdown bounded with truncation and explicit opt-in for full output.

**Pros:**
- Best trade-off for CLI usage patterns.
- Keeps human-readable modes usable.

**Cons:**
- Two behavior models to document.

**Effort:** Medium-Large

**Risk:** Low-Medium

## Recommended Action


## Technical Details

**Affected files:**
- `lib/langfuse/cli/client.rb:135`
- `lib/langfuse/cli/commands/traces.rb:117`
- `lib/langfuse/cli/commands/sessions.rb:73`
- `lib/langfuse/cli/commands/observations.rb:113`
- `lib/langfuse/cli/commands/scores.rb:74`
- `lib/langfuse/cli/commands/metrics.rb:148`
- `lib/langfuse/cli/formatters/markdown_formatter.rb:7`
- `lib/langfuse/cli/formatters/csv_formatter.rb:8`

**Related components:**
- Output formatter stack
- Client pagination behavior

**Database changes (if any):**
- No

## Resources

- Review target: current `main` branch
- User concern: large traces (10MB/20MB/40MB)
- Related formatter specs: `spec/unit/formatters/markdown_formatter_spec.rb`, `spec/unit/formatters/csv_formatter_spec.rb`

## Acceptance Criteria

- [ ] Export path does not require full in-memory formatted string for JSON and CSV.
- [ ] Large trace export (>=40MB payload) completes without OOM in normal environment.
- [ ] CLI emits clear warning/error before unsafe output sizes for table/markdown.
- [ ] New tests cover large payload behavior and limit enforcement.
- [ ] Documentation explains large-output behavior and recommended formats.

## Work Log

### 2026-02-10 - Code Review Discovery

**By:** Codex

**Actions:**
- Reviewed output pipeline across all command classes.
- Traced memory-heavy paths in formatter and write flow.
- Ran synthetic benchmark on 10MB/20MB/40MB payload strings.

**Learnings:**
- Existing flow duplicates large payloads across stages.
- No guardrails exist for large-output modes.

## Notes

- This is merge-blocking for users exporting large traces in current form.
