# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Support for filtering by metadata
- Trace export with full observation trees
- Watch mode for real-time trace monitoring
- Creating/updating scores via CLI
- Integration with other observability tools

## [1.0.2] - 2026-02-11

### Changed
- `json` is now the default output format for all commands.
- Removed `markdown` as a supported output format.
- `lf traces get` now always returns an `observations` field in output.

### Removed
- Removed `--with-observations` / `--no-with-observations` from `lf traces get`.

## [1.0.1] - 2026-02-10

### Added
- Safety limits for large `table` and `markdown` cells to prevent runaway terminal output.
- New unit tests for large payload formatting, markdown multiline handling, and config fallback/validation behavior.

### Changed
- `json` output now writes compact JSON when `--output` is used, reducing memory pressure for large traces.
- CLI command guidance now consistently uses `lf ...` in command help and error messages.
- README output behavior docs now describe truncation and file-output JSON behavior.

### Fixed
- Markdown table export now normalizes multiline values to `<br>` so table rows remain valid.
- Config profile resolution now falls back to `profiles.default` when requested profile is missing.
- Blank env/option credentials are now treated as missing during config validation.

### Security
- Switched config parsing to safe YAML loading.

## [1.0.0] - 2025-01-23

### Added
- Initial release of lf-cli (renamed from langfuse-cli)
- Interactive configuration setup with browser integration
- Traces command with list and get operations
- Sessions command with list and show operations
- Observations command with list and get operations
- Scores command with list and get operations
- Metrics command with query operation and custom aggregations
- Support for multiple output formats (table, JSON, CSV, markdown)
- Multi-profile configuration support
- Automatic pagination for list operations
- Time range filtering with ISO 8601 and natural language support
- Sorbet Runtime type safety with T::Enum and T::Struct
- Comprehensive help messages with valid values and examples
- 55 passing unit tests with 100% success rate

### Changed
- Renamed project from `langfuse-cli` to `lf-cli` for trademark compliance
- Renamed executable from `langfuse` to `lf`
- Updated description to clarify unofficial/community status

### Security
- Configuration file created with 0600 permissions (owner read/write only)
- API keys masked in configuration display commands
- Connection validation before saving credentials
