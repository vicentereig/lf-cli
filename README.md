# lf-cli

**An open-source CLI for Langfuse®**

A powerful command-line interface for querying and analyzing Langfuse LLM observability data. Built with Ruby and designed for developers who prefer working in the terminal.

[![Gem Version](https://img.shields.io/gem/v/lf-cli)](https://rubygems.org/gems/lf-cli)
[![Total Downloads](https://img.shields.io/gem/dt/lf-cli)](https://rubygems.org/gems/lf-cli)
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

## LLM Reference (llms-full)

This section mirrors the depth of a `llms-full.txt` so AI assistants can answer detailed questions about `lf-cli` without inspecting the source.

### CLI Metadata

| Item | Details |
| --- | --- |
| Binary names | `lf` (preferred), `langfuse` (legacy alias used in docs) |
| Entry point | `bin/lf` → `Langfuse::CLI::Main.start(ARGV)` |
| Ruby compatibility | Ruby >= 2.7.0 (same as gemspec requirement) |
| Default API host | `https://cloud.langfuse.com` |
| Config path | `~/.langfuse/config.yml` (`0600` permissions) |
| Source namespace | `Langfuse::CLI` with command classes under `lib/langfuse/cli/commands` |
| HTTP stack | Faraday + JSON middleware, 2s open/read timeouts, retry with exponential backoff on `429/5xx` |
| Logging | Set `DEBUG=1` to enable Faraday request/response logging |

### Authentication & Configuration

1. Credentials (`public_key`, `secret_key`) plus `host` are mandatory for all API calls.
2. Resolution order: CLI flags → environment variables → profile in `~/.langfuse/config.yml` → defaults.
3. Profiles let you store multiple environments (e.g., `default`, `staging`, `production`) inside the same YAML file.
4. The `config setup` command validates keys before saving by hitting `/api/public/traces` with `limit=1`.

**Environment variable matrix**

| Variable | Purpose | Required | Notes |
| --- | --- | --- | --- |
| `LANGFUSE_PUBLIC_KEY` | Public API key | ✅ | Required for non-interactive `config setup` and all other commands if no profile is configured. |
| `LANGFUSE_SECRET_KEY` | Secret API key | ✅ | Same priority rules as the public key. |
| `LANGFUSE_HOST` | Override API base URL | Optional | Use for self-hosted Langfuse instances. |
| `LANGFUSE_PROFILE` | Profile name | Optional | Overrides the profile selected via `-P/--profile`. |
| `LANGFUSE_PROJECT_NAME` | Used by `config setup` to show the correct settings URL. | Optional | Only needed for UX hints. |
| `DEBUG` | When set to `1`, logs Faraday requests/responses to stdout. | Optional | Useful for diagnosing API issues. |

### Global Flags & Behavior

| Flag | Description | Notes |
| --- | --- | --- |
| `-P, --profile PROFILE` | Selects a saved profile. | Defaults to `default`. |
| `--public-key KEY` / `--secret-key KEY` | Inject credentials without touching config files. | Highest priority source. |
| `--host URL` | Override Langfuse host. | Combine with `--profile` to temporarily test another region. |
| `-f, --format FORMAT` | `table` (default), `json`, `csv`, `markdown`. | Applies to every command; CSV/Markdown require structured arrays. |
| `-o, --output PATH` | Write output to a file. | Respects format; prints “Output written…” when `--verbose`. |
| `-l, --limit N` | Caps number of records pulled per command. | Pagination helper, defaults to API `limit` (50) when omitted. |
| `-p, --page N` | Start from an explicit page. | Useful when you know an offset. |
| `--from`, `--to` | ISO 8601 or natural language timestamps. | Natural language parsing uses `chronic` if installed; otherwise the string is sent as-is. |
| `-v, --verbose` | Prints extra logs (e.g., file paths). | Some commands emit status lines prefixed with emojis. |
| `--no-color` | Forces monochrome table output. | Forwarded to formatters that support color. |

Pagination strategy: the client keeps fetching pages until it collects the requested `limit` or no more pages remain. `limit` therefore caps the total combined size, not per-page size.

### Output & Files

- `table` renders ASCII tables via `Formatters::TableFormatter`.
- `json` streams `JSON.pretty_generate` for direct piping to `jq`.
- `csv` and `markdown` use dedicated formatters and require array-like data (single hashes are wrapped automatically).
- `--output` writes the formatted string verbatim; combine with `--format json` for scripts.
- Use `lf ... --format json | jq ...` for automation recipes.

### Command Reference

Each command inherits the global flags above. API errors exit with status code `1`.

#### `config` (profile management)

| Subcommand | Synopsis | Notes |
| --- | --- | --- |
| `lf config setup` | Interactive wizard; supports env-variable non-interactive mode. | Tests credentials before saving. |
| `lf config set PROFILE --public-key ... --secret-key ... [--host ...]` | Writes/updates a profile directly. | Does not hit the API. |
| `lf config show [PROFILE]` | Prints the resolved profile (keys masked). | Reads from YAML + ENV. |
| `lf config list` | Shows every profile name plus masked public key/host. | Warns if file missing. |

#### `traces`

| Subcommand | Purpose |
| --- | --- |
| `lf traces list` | Lists traces with filters/pagination. |
| `lf traces get TRACE_ID [--with-observations]` | Fetches a single trace. The `--with-observations` flag is accepted for forward compatibility but currently behaves the same as the default API payload. |

`traces list` options:

| Flag | Type | Description |
| --- | --- | --- |
| `--name NAME` | String | Filter by trace name. |
| `--user-id USER_ID` | String | Filter by Langfuse user identifier. |
| `--session-id SESSION_ID` | String | Filter by session. |
| `--tags TAG1 TAG2` | Array | Matches traces containing all provided tags. |
| `--from`, `--to` | String | Time boundaries; accepts ISO 8601 or relative strings. |
| `--limit`, `--page` | Numeric | Override pagination per request. |

Sample workflow:

```bash
latest_trace_id=$(lf traces list --format json --limit 1 | jq -r '.[0].id')
lf traces get "$latest_trace_id" --format json > trace.json
```

#### `sessions`

| Subcommand | Purpose |
| --- | --- |
| `lf sessions list` | Enumerates sessions. |
| `lf sessions show SESSION_ID [--with-traces]` | Shows a session and optionally its traces (flag reserved for future enrichments). |

Options mirror trace pagination: `--from`, `--to`, `--limit`, `--page`.

#### `observations`

| Subcommand | Purpose |
| --- | --- |
| `lf observations list` | Lists generations, spans, or events. |
| `lf observations get OBSERVATION_ID` | Fetches a single observation. |

`list` filters:

| Flag | Values | Description |
| --- | --- | --- |
| `--type` | `generation`, `span`, `event` | Restrict to an observation type. |
| `--trace-id` | Trace ID | Only observations under a specific trace. |
| `--name` | String | Filter by observation name. |
| `--user-id` | String | Filter by associated user. |
| `--from`, `--to`, `--limit`, `--page` | As described earlier. |

#### `scores`

| Subcommand | Purpose |
| --- | --- |
| `lf scores list` | Lists evaluation scores. |
| `lf scores get SCORE_ID` | Fetches a single score document. |

Filters: `--name`, `--from`, `--to`, `--limit`, `--page`.

#### `metrics`

Single subcommand: `lf metrics query`.

Required flags:

| Flag | Allowed values | Description |
| --- | --- | --- |
| `--view` | `traces`, `observations`, `scores-numeric`, `scores-categorical` | Which metrics view to query. |
| `--measure` | `count`, `latency`, `value`, `tokens`, `cost` | Base metric. |
| `--aggregation` | `count`, `sum`, `avg`, `p50`, `p95`, `p99`, `min`, `max`, `histogram` | Aggregation function. |

Optional flags:

| Flag | Description |
| --- | --- |
| `--dimensions field1 field2` | Array of dimension field names (e.g., `name`, `userId`, `sessionId`, `model`). |
| `--from`, `--to` | Time range. |
| `--granularity` | `minute`, `hour`, `day`, `week`, `month`, `auto`. Controls the time bucket. |
| `--limit` | Defaults to `100` for metrics; caps the number of buckets/rows returned. |

The CLI builds a payload matching the Langfuse metrics API (`metrics` array, `timeDimension` etc.) via `Langfuse::CLI::Types::MetricsQuery`.

### Data Model Cheat Sheet

- **Trace**: `id`, `name`, `userId`, `sessionId`, `timestamp`, `durationMs`, `tags[]`, `metadata` (object), `observations[]` (optional when using `get`), `scores[]`.
- **Session**: `id`, `userId`, `name`, `createdAt`, `updatedAt`, `traceIds[]`, `metadata`.
- **Observation**: `id`, `traceId`, `type` (`generation/span/event`), `name`, `status`, `model`, `input`, `output`, `metrics` (latency, usage), `level`, `parentObservationId`.
- **Score**: `id`, `name`, `value` (number/string), `type` (`numeric`/`categorical`), `traceId`, `observationId`, `timestamp`, `metadata`, `comment`.
- **Metrics response**: Usually `{ "data": [ { "dimensions": {...}, "metrics": {...} } ], "meta": {...} }`. The CLI automatically unwraps `data` before formatting.

Fields are passed through verbatim from the Langfuse Public API; the CLI never renames keys.

### Error Handling & Exit Codes

- Success exits with code `0`.
- Any `Langfuse::CLI::Client::*Error` results in exit code `1` after printing a human-readable message.
- Specific messages:
  - `Authentication Error` for `401`.
  - `Rate limit exceeded` for `429`.
  - `Trace/session/... not found` for `404`.
  - `Request timed out` when Faraday raises a timeout (usually after 2s).
- Use `--verbose` or `DEBUG=1` for deeper context (e.g., stack traces, Faraday logs).

### Troubleshooting & Automation Tips

- **Network issues**: verify `LANGFUSE_HOST` by running `lf config show` and hitting `/health` with `curl`.
- **Time parsing**: install the `chronic` gem to enable natural language ranges; otherwise pass ISO 8601 timestamps.
- **CSV exports**: always provide `--output file.csv` to avoid large terminal dumps.
- **Scripting**: prefer `--format json` to keep machine-readable structures. Most commands return arrays, so piping to `jq '.[].id'` works consistently.
- **Profiles**: store CI credentials under `LANGFUSE_PROFILE=ci` and load them via `lf ... -P ci` to keep human/dev credentials untouched.
- **Retries**: built-in Faraday retry middleware already backs off (`max: 3`). For long-running scripts, wrap commands with shell retries instead of adding loops inside the CLI.

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
