# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]

### Planned
- Support for filtering by metadata
- Trace export with full observation trees
- Watch mode for real-time trace monitoring
- Creating/updating scores via CLI
- Integration with other observability tools
