---
status: pending
priority: p2
issue_id: "004"
tags: [code-review, auth, config, reliability]
dependencies: []
---

# Fix config profile fallback behavior

When the selected profile does not exist in `profiles`, config loading falls back to a legacy root key only, not `profiles.default`.

## Problem Statement

Auth/config can look broken when profile selection is wrong or stale. Instead of falling back to the saved default profile, the loader can drop credentials entirely.

## Findings

- Current fallback logic: `config_data.dig('profiles', @profile) || config_data['default'] || {}` (`lib/langfuse/cli/config.rb:45`).
- Saved config writes profiles under `config_data['profiles'][profile_name]` (`lib/langfuse/cli/config.rb:98`), including `"default"` by convention.
- If `@profile` is missing and file uses the `profiles` structure, fallback to `profiles.default` is skipped.
- This manifests as missing credential errors despite valid config file contents.

## Proposed Solutions

### Option 1: Add `profiles.default` fallback

**Approach:** Resolve profile in order: `profiles[@profile]`, `profiles['default']`, legacy `default`.

**Pros:**
- Fixes common misconfiguration path.
- Backward-compatible.

**Cons:**
- Slightly more branching in loader.

**Effort:** Small

**Risk:** Low

---

### Option 2: Fail fast with explicit profile-not-found error

**Approach:** Raise error when requested profile is absent; do not fallback implicitly.

**Pros:**
- Clear and explicit behavior.
- Reduces hidden config surprises.

**Cons:**
- More strict than current behavior.
- Might break existing expectations.

**Effort:** Small

**Risk:** Medium

## Recommended Action


## Technical Details

**Affected files:**
- `lib/langfuse/cli/config.rb:41`
- `spec/unit/config_spec.rb:126`

**Related components:**
- Profile resolution
- Auth bootstrap for all command clients

**Database changes (if any):**
- No

## Resources

- Config loader implementation: `lib/langfuse/cli/config.rb`
- Config tests: `spec/unit/config_spec.rb`

## Acceptance Criteria

- [ ] Missing profile falls back to `profiles.default` (or emits explicit error if chosen design).
- [ ] Unit tests cover nonexistent profile with `profiles.default` present.
- [ ] Behavior is documented in README config section.

## Work Log

### 2026-02-10 - Code Review Discovery

**By:** Codex

**Actions:**
- Traced profile load and save paths.
- Compared YAML shape expected on read vs written on save.

**Learnings:**
- Fallback path is incomplete for current canonical config structure.

## Notes

- This issue aligns with “config never got it to work correctly” user feedback.
