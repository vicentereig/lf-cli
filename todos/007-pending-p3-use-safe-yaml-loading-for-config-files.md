---
status: pending
priority: p3
issue_id: "007"
tags: [code-review, security, config]
dependencies: []
---

# Use safe YAML parsing for local config

Config parsing uses `YAML.load_file`, which can deserialize arbitrary objects. For local config this is lower risk, but safe parsing is still preferred.

## Problem Statement

Unsafe YAML deserialization is a known hardening concern. Even in local tooling, replacing it with safe parsing reduces attack surface and aligns with secure defaults.

## Findings

- Config load uses `YAML.load_file` (`lib/langfuse/cli/config.rb:42`).
- Config save/load path is user-home based (`~/.langfuse/config.yml`).
- Profile listing command also uses `YAML.load_file` (`lib/langfuse/cli/commands/config.rb:145`).

## Proposed Solutions

### Option 1: Replace with `YAML.safe_load` + permitted classes

**Approach:** Read file text and parse via `YAML.safe_load` constrained to expected scalar/hash structures.

**Pros:**
- Improves security posture.
- Minimal runtime behavior change.

**Cons:**
- Requires careful handling for symbol/string key differences.

**Effort:** Small

**Risk:** Low

---

### Option 2: Keep parser, enforce strict file ownership and mode checks

**Approach:** Validate file permissions/ownership before loading.

**Pros:**
- Hardening without parser change.

**Cons:**
- Does not remove unsafe deserialization vector.

**Effort:** Small

**Risk:** Medium

## Recommended Action


## Technical Details

**Affected files:**
- `lib/langfuse/cli/config.rb:42`
- `lib/langfuse/cli/commands/config.rb:145`

**Related components:**
- Config lifecycle
- Local security hardening

**Database changes (if any):**
- No

## Resources

- Ruby Psych/YAML security guidance
- Existing config parser code paths

## Acceptance Criteria

- [ ] Config parsing uses safe YAML loading.
- [ ] Behavior remains compatible with existing config file shape.
- [ ] Tests cover malformed and unexpected YAML structures.

## Work Log

### 2026-02-10 - Code Review Discovery

**By:** Codex

**Actions:**
- Reviewed config parser and profile listing reader.
- Flagged unsafe deserialization usage.

**Learnings:**
- Risk is low-to-moderate but easy to harden.

## Notes

- Marked P3 because this is hardening, not a currently exploited path.
