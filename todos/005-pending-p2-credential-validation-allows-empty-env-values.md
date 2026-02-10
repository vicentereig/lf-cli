---
status: pending
priority: p2
issue_id: "005"
tags: [code-review, auth, validation, env]
dependencies: []
---

# Reject blank credentials and host values from env/options

Configuration validity checks treat empty strings as valid credentials, which leads to opaque authentication failures instead of clear configuration errors.

## Problem Statement

If environment variables are present but blank (or whitespace), config passes validation and sends broken auth requests. This creates poor debugging experience and false negatives for auth health.

## Findings

- `Config#valid?` checks only for `nil` (`lib/langfuse/cli/config.rb:73`).
- `missing_fields` also checks only `nil` (`lib/langfuse/cli/config.rb:80`).
- `load_from_env` and `merge_options` accept any non-`nil` values, including empty strings (`lib/langfuse/cli/config.rb:58`, `lib/langfuse/cli/config.rb:65`).
- Commands surface API/auth errors later, not config validation errors.

## Proposed Solutions

### Option 1: Normalize and validate presence (`nil` or blank)

**Approach:** Strip values on load/merge; treat blank as missing in `valid?` and `missing_fields`.

**Pros:**
- Fast and explicit fix.
- Better user-facing errors.

**Cons:**
- Could change behavior for users relying on blank host placeholders.

**Effort:** Small

**Risk:** Low

---

### Option 2: Add strict validation mode and warnings

**Approach:** Keep current behavior but warn loudly when values are blank.

**Pros:**
- Less behavioral risk.

**Cons:**
- Still allows broken requests by default.

**Effort:** Small

**Risk:** Medium

## Recommended Action


## Technical Details

**Affected files:**
- `lib/langfuse/cli/config.rb:57`
- `lib/langfuse/cli/config.rb:63`
- `lib/langfuse/cli/config.rb:73`
- `spec/unit/config_spec.rb:163`

**Related components:**
- Auth bootstrap for all commands

**Database changes (if any):**
- No

## Resources

- Config validation implementation: `lib/langfuse/cli/config.rb`
- Command-level error wrappers: `lib/langfuse/cli/commands/traces.rb:62` (same pattern elsewhere)

## Acceptance Criteria

- [ ] Blank/whitespace `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, and `LANGFUSE_HOST` are treated as missing.
- [ ] CLI fails early with missing field guidance before API request.
- [ ] Unit tests cover blank env and blank options values.

## Work Log

### 2026-02-10 - Code Review Discovery

**By:** Codex

**Actions:**
- Audited config validation and merging behavior.
- Verified nil-only checks in validity and missing-field logic.

**Learnings:**
- Validation currently catches too little and defers errors to runtime auth calls.

## Notes

- This is a likely source of “env injection not working” symptoms.
