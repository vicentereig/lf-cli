# lf-cli

**An open-source CLI for Langfuse®**

A powerful command-line interface for querying and analyzing Langfuse LLM observability data. Built with Ruby and designed for developers who prefer working in the terminal.

[![Gem Version](https://badge.fury.io/rb/lf-cli.svg)](https://badge.fury.io/rb/lf-cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Disclaimer

**This is an unofficial, community-maintained CLI tool for Langfuse.**

This project is not affiliated with, endorsed by, or sponsored by Langfuse GmbH. Langfuse® is a registered trademark of Langfuse GmbH.

## Features

- 🔍 **Query Traces** - List and filter traces by name, user, session, tags, or time range
- 📊 **Analyze Sessions** - View complete session details with all associated traces
- 🎯 **Inspect Observations** - List LLM generations, spans, and events
- 📈 **Query Metrics** - Run analytics queries with custom aggregations and dimensions
- ⭐ **View Scores** - Access quality scores and evaluation metrics
- 🎨 **Multiple Output Formats** - Table, JSON, CSV, or Markdown
- 🔐 **Multi-Profile Support** - Manage credentials for dev, staging, and production
- 🌐 **Interactive Setup** - Browser-integrated credential configuration
- ⚡ **Type-Safe** - Built with Sorbet Runtime for reliability

## Installation

### Install from RubyGems

```bash
gem install lf-cli
```

### Install from Source

```bash
git clone https://github.com/vicentereig/lf-cli.git
cd lf-cli
bundle install
bundle exec rake install
```

### Requirements

- Ruby >= 2.7.0
- Langfuse account (cloud or self-hosted)

## Quick Start

### 1. Configure Credentials

Run the interactive setup wizard:

```bash
lf config setup
```

This will:
1. Ask for your Langfuse project name
2. Open your browser to the Langfuse settings page
3. Prompt you to enter your API keys
4. Test the connection
5. Save credentials securely to `~/.langfuse/config.yml`

### 2. Start Querying

```bash
# List recent traces
lf traces list --from "1 hour ago" --limit 20

# Get specific trace details
lf traces get trace_abc123

# Query metrics
lf metrics query --view traces --measure count --aggregation count
```

## Usage

### Configuration Commands

```bash
# Interactive setup (recommended)
lf config setup

# Set credentials manually
lf config set production \
  --public-key pk_... \
  --secret-key sk_...

# Show current configuration (keys are masked)
lf config show

# List all profiles
lf config list
```

### Trace Commands

```bash
# List all traces
lf traces list

# Filter traces by various criteria
lf traces list \
  --name "chat_completion" \
  --user-id user_123 \
  --from "2024-01-01" \
  --limit 50

# Get detailed trace information
lf traces get trace_abc123

# Export to CSV
lf traces list --format csv --output traces.csv
```

### Session Commands

```bash
# List all sessions
lf sessions list

# Show specific session with details
lf sessions show session_xyz789
```

### Observation Commands

```bash
# List all observations
lf observations list

# Filter by type
lf observations list --type generation

# Filter by trace
lf observations list --trace-id trace_abc123
```

### Score Commands

```bash
# List all scores
lf scores list

# Filter by name
lf scores list --name quality

# Get specific score
lf scores get score_123
```

### Metrics Commands

```bash
# Count total traces
lf metrics query \
  --view traces \
  --measure count \
  --aggregation count

# Average latency by trace name
lf metrics query \
  --view observations \
  --measure latency \
  --aggregation avg \
  --dimensions name

# Token usage with time range
lf metrics query \
  --view observations \
  --measure tokens \
  --aggregation sum \
  --from "2024-01-01" \
  --to "2024-12-31"

# P95 latency grouped by model
lf metrics query \
  --view observations \
  --measure latency \
  --aggregation p95 \
  --dimensions model
```

### Global Options

All commands support these global options:

```bash
-f, --format [table|json|csv|markdown]   # Output format (default: table)
-o, --output FILE                        # Save output to file
-l, --limit N                            # Limit number of results
-P, --profile PROFILE                    # Use specific profile
--from TIMESTAMP                         # Start of time range (ISO 8601 or relative)
--to TIMESTAMP                           # End of time range
-v, --verbose                            # Verbose output
```

### Time Range Examples

Supports both ISO 8601 and natural language:

```bash
# ISO 8601
--from "2024-01-01T00:00:00Z" --to "2024-12-31T23:59:59Z"

# Natural language (requires 'chronic' gem)
--from "1 hour ago"
--from "yesterday"
--from "last monday"
```

## Output Formats

### Table (Default)

```bash
lf traces list --format table
```

Outputs a formatted ASCII table - great for terminal viewing.

### JSON

```bash
lf traces list --format json
```

Perfect for piping to `jq` or other tools:

```bash
lf traces list --format json | jq '.[] | select(.name == "chat")'
```

### CSV

```bash
lf traces list --format csv --output data.csv
```

Import into spreadsheets or data analysis tools.

### Markdown

```bash
lf traces list --format markdown
```

Great for documentation and reports.

## Configuration

### Configuration File

Credentials are stored in `~/.langfuse/config.yml`:

```yaml
profiles:
  default:
    host: https://cloud.langfuse.com
    public_key: pk_...
    secret_key: sk_...
    output_format: table
    page_limit: 50

  production:
    host: https://cloud.langfuse.com
    public_key: pk_prod_...
    secret_key: sk_prod_...
```

The file is created with `0600` permissions (owner read/write only) for security.

### Environment Variables

You can also use environment variables:

```bash
export LANGFUSE_PUBLIC_KEY="pk_..."
export LANGFUSE_SECRET_KEY="sk_..."
export LANGFUSE_HOST="https://cloud.langfuse.com"
export LANGFUSE_PROFILE="production"
```

### Priority Order

Configuration is loaded in this order (highest to lowest priority):

1. Command-line flags (`--public-key`, `--secret-key`, etc.)
2. Environment variables (`LANGFUSE_PUBLIC_KEY`, etc.)
3. Config file (`~/.langfuse/config.yml`)
4. Defaults

## Development

### Setup

```bash
git clone https://github.com/vicentereig/lf-cli.git
cd lf-cli
bundle install
```

### Run Tests

```bash
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/unit/commands/traces_spec.rb
```

### Run CLI Locally

```bash
./bin/lf help
./bin/lf config setup
```

### Code Structure

```
lib/langfuse/cli/
├── client.rb           # API client with Faraday
├── config.rb           # Configuration management
├── types.rb            # Sorbet type definitions
├── formatters/         # Output formatters
│   ├── table_formatter.rb
│   ├── csv_formatter.rb
│   └── markdown_formatter.rb
└── commands/           # Command modules
    ├── traces.rb
    ├── sessions.rb
    ├── observations.rb
    ├── scores.rb
    ├── metrics.rb
    └── config.rb
```

## API Reference

This CLI uses the Langfuse Public API:

- **API Documentation**: https://api.reference.langfuse.com/
- **OpenAPI Spec**: https://cloud.langfuse.com/generated/api/openapi.yml

Valid enum values for `metrics query`:

- **View**: `traces`, `observations`, `scores-numeric`, `scores-categorical`
- **Measure**: `count`, `latency`, `value`, `tokens`, `cost`
- **Aggregation**: `count`, `sum`, `avg`, `p50`, `p95`, `p99`, `min`, `max`, `histogram`
- **Granularity**: `minute`, `hour`, `day`, `week`, `month`, `auto`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Thor](https://github.com/rails/thor) CLI framework
- Uses [Faraday](https://github.com/lostisland/faraday) for HTTP requests
- Type safety with [Sorbet Runtime](https://sorbet.org/)
- Inspired by the excellent [Langfuse](https://langfuse.com/) observability platform

## Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/vicentereig/lf-cli/issues)
- 💬 **Questions**: [GitHub Discussions](https://github.com/vicentereig/lf-cli/discussions)
- 📧 **Email**: hey@vicente.services

## Roadmap

- [ ] Add support for filtering by metadata
- [ ] Implement trace export with full observation trees
- [ ] Add watch mode for real-time trace monitoring
- [ ] Support for creating/updating scores via CLI
- [ ] Integration with other observability tools

---

**Note**: This is a community project. For official Langfuse support and documentation, visit [langfuse.com](https://langfuse.com/).
