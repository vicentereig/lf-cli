# Langfuse CLI Tool - Comprehensive Design Plan

## Executive Summary

A standalone Ruby gem (`langfuse-cli`) that provides comprehensive command-line access to Langfuse telemetry data. The tool will support multiple output formats (terminal UI, tables, JSON, CSV, markdown) and cover all major use cases: trace debugging, performance monitoring, session analysis, and data export.

## Project Goals

### Primary Objectives
1. **Quick Trace Lookup & Debugging** - Search and view individual traces/observations by ID, name, or filters
2. **Performance Monitoring** - Check latency, token usage, costs, and other metrics over time
3. **Session Analysis** - View and analyze complete agent sessions with all traces
4. **Data Export** - Export telemetry data to JSON/CSV for further analysis

### User Experience Goals
- Zero-configuration start (uses environment variables)
- Fast and responsive queries with pagination support
- Rich terminal UI with colors and formatting
- Machine-readable output for scripting
- Intuitive command structure following UNIX conventions

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     CLI Interface (Thor)                     │
├─────────────────────────────────────────────────────────────┤
│  traces  │ sessions │ observations │ metrics │ scores │ tui │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
         ┌───────────────────────────────────┐
         │       API Client (Faraday)        │
         │   - Basic Auth                    │
         │   - Pagination                    │
         │   - Error Handling                │
         └───────────────────────────────────┘
                             │
                             ▼
         ┌───────────────────────────────────┐
         │   Langfuse REST API               │
         │   (cloud.langfuse.com)            │
         └───────────────────────────────────┘
                             │
                             ▼
         ┌───────────────────────────────────┐
         │        Formatters                 │
         │  Table │ JSON │ CSV │ MD │ TUI    │
         └───────────────────────────────────┘
```

### Core Components

#### 1. API Client (`lib/langfuse/cli/client.rb`)

The HTTP client that communicates with Langfuse API:

**Responsibilities:**
- HTTP request/response handling with Faraday
- Basic Authentication using public/secret key pairs
- Automatic pagination for list endpoints
- Error handling and retry logic
- Response parsing and validation

**Key Methods:**
```ruby
class Langfuse::CLI::Client
  # Traces
  def list_traces(filters = {})
  def get_trace(trace_id)

  # Sessions
  def list_sessions(filters = {})
  def get_session(session_id)

  # Observations
  def list_observations(filters = {})
  def get_observation(observation_id)

  # Metrics
  def query_metrics(query_params)

  # Scores
  def list_scores(filters = {})
  def get_score(score_id)

  private

  def request(method, path, params = {})
  def paginate(path, params = {})
  def handle_error(response)
end
```

#### 2. CLI Interface (`lib/langfuse/cli.rb`)

Built with Thor gem, provides the command-line interface:

**Global Options:**
- `--format` / `-f` - Output format: table, json, csv, markdown
- `--output` / `-o` - Output file path (defaults to stdout)
- `--limit` / `-l` - Limit number of results
- `--page` / `-p` - Page number for pagination
- `--host` - Langfuse host URL (default: cloud.langfuse.com)
- `--verbose` / `-v` - Verbose output
- `--no-color` - Disable colored output

**Configuration Priority:**
1. Command-line flags
2. Environment variables
3. Config file (`~/.langfuse/config.yml`)
4. Defaults

#### 3. Command Modules (`lib/langfuse/cli/commands/`)

Each major resource gets its own command module:

##### Traces Command (`traces.rb`)
```bash
# List traces with filters
langfuse traces list [OPTIONS]
  --from TIMESTAMP          # ISO 8601 or relative (e.g., "1 hour ago")
  --to TIMESTAMP            # ISO 8601 or relative
  --name NAME               # Trace name filter
  --user-id USER_ID         # Filter by user ID
  --session-id SESSION_ID   # Filter by session
  --tags TAG1,TAG2          # Filter by tags
  --metadata KEY:VALUE      # Filter by metadata
  --format FORMAT           # Output format

# Get specific trace with all observations
langfuse traces get TRACE_ID [OPTIONS]
  --with-observations       # Include all observations
  --format FORMAT

# Search traces with complex filters
langfuse traces search [OPTIONS]
  --query QUERY             # Search in trace names/metadata
```

##### Sessions Command (`sessions.rb`)
```bash
# List sessions
langfuse sessions list [OPTIONS]
  --from TIMESTAMP
  --to TIMESTAMP
  --format FORMAT

# Show session with all traces
langfuse sessions show SESSION_ID [OPTIONS]
  --with-traces             # Include all traces
  --format FORMAT

# Get session statistics
langfuse sessions stats SESSION_ID
```

##### Observations Command (`observations.rb`)
```bash
# List observations
langfuse observations list [OPTIONS]
  --trace-id TRACE_ID       # Filter by trace
  --name NAME
  --type TYPE               # generation, span, event
  --from TIMESTAMP
  --to TIMESTAMP
  --format FORMAT

# Get specific observation
langfuse observations get OBSERVATION_ID [OPTIONS]
  --format FORMAT
```

##### Metrics Command (`metrics.rb`)
```bash
# Query metrics with custom aggregations
langfuse metrics query [OPTIONS]
  --view VIEW               # traces, observations, scores-numeric, scores-categorical
  --from TIMESTAMP          # Required
  --to TIMESTAMP            # Required
  --dimensions FIELDS       # Comma-separated: name,userId,model
  --metrics SPECS           # Comma-separated: count,latency:avg,cost:sum,tokens:sum
  --filters FILTERS         # JSON string or key:op:value format
  --granularity PERIOD      # minute, hour, day, week, month, auto
  --format FORMAT

# Common metric queries (shortcuts)
langfuse metrics usage --from "7 days ago"     # Token/cost usage
langfuse metrics latency --from "24 hours ago" # Latency stats
langfuse metrics errors --from "1 hour ago"    # Error rates
```

##### Scores Command (`scores.rb`)
```bash
# List scores
langfuse scores list [OPTIONS]
  --from TIMESTAMP
  --to TIMESTAMP
  --name NAME               # Score name filter
  --format FORMAT

# Get specific score
langfuse scores get SCORE_ID [OPTIONS]
  --format FORMAT
```

##### Terminal UI Command (`tui.rb`)
```bash
# Launch interactive terminal UI
langfuse tui [OPTIONS]
  --session-id SESSION_ID   # Start with specific session
  --trace-id TRACE_ID       # Start with specific trace
```

#### 4. Formatters (`lib/langfuse/cli/formatters/`)

Each formatter implements a common interface:

```ruby
module Langfuse::CLI::Formatters
  class Base
    def format(data)
      raise NotImplementedError
    end
  end

  class TableFormatter < Base
    # Uses terminal-table gem
    # Produces ASCII tables with colors
  end

  class JsonFormatter < Base
    # Pretty JSON output
    # Supports --compact flag for minified JSON
  end

  class CsvFormatter < Base
    # CSV export using stdlib CSV
    # Handles nested objects by flattening
  end

  class MarkdownFormatter < Base
    # Markdown tables
    # Great for documentation/reports
  end

  class TuiFormatter < Base
    # Interactive terminal UI
    # Uses tty-prompt, tty-table
    # Live updates, navigation, search
  end
end
```

#### 5. Configuration Management (`lib/langfuse/cli/config.rb`)

```ruby
module Langfuse::CLI
  class Config
    # Loads configuration from multiple sources
    # Priority: CLI flags > ENV vars > config file > defaults

    attr_accessor :public_key, :secret_key, :host, :defaults

    def self.load
      # Load from ~/.langfuse/config.yml
      # Merge with environment variables
    end

    def save
      # Save to ~/.langfuse/config.yml
    end
  end
end
```

**Config File Format (`~/.langfuse/config.yml`):**
```yaml
default:
  host: https://cloud.langfuse.com
  public_key: pk_xxx
  secret_key: sk_xxx
  output_format: table
  page_limit: 50

profiles:
  production:
    host: https://cloud.langfuse.com
    public_key: pk_prod_xxx
    secret_key: sk_prod_xxx

  development:
    host: https://cloud.langfuse.com
    public_key: pk_dev_xxx
    secret_key: sk_dev_xxx
```

**Environment Variables:**
- `LANGFUSE_PUBLIC_KEY` - API public key
- `LANGFUSE_SECRET_KEY` - API secret key
- `LANGFUSE_HOST` - Langfuse host URL
- `LANGFUSE_PROFILE` - Config profile to use

## OpenAPI Specification Reference

The Langfuse API is fully documented using OpenAPI specification:

**Primary Source:**
- **OpenAPI Spec**: https://cloud.langfuse.com/generated/api/openapi.yml

**Alternative Locations:**
- **GitHub (JS SDK)**: https://github.com/langfuse/langfuse-js/blob/main/langfuse-core/openapi-spec/openapi-server.yaml
- **Interactive API Reference**: https://api.reference.langfuse.com/ (browse and download spec)
- **Postman Collection**: https://cloud.langfuse.com/generated/postman/collection.json

**Usage During Development:**
- Reference for validating endpoint parameters and response schemas
- Check for API changes and version updates
- Generate client code or request/response validations
- Verify authentication requirements

## API Endpoints Reference

Based on the OpenAPI spec analysis, here are the key endpoints we'll use:

### Traces API

**GET /api/public/traces**
- List traces with pagination and filters
- Parameters:
  - `page` (integer) - Page number, starts at 1
  - `limit` (integer) - Items per page
  - `userId` (string) - Filter by user ID
  - `name` (string) - Filter by trace name
  - `sessionId` (string) - Filter by session
  - `tags` (array) - Filter by tags
  - `fromTimestamp` (ISO 8601) - Start of time range
  - `toTimestamp` (ISO 8601) - End of time range

**GET /api/public/traces/{traceId}**
- Get specific trace with all observations
- Returns complete trace hierarchy

### Sessions API

**GET /api/public/sessions**
- List sessions with pagination
- Parameters:
  - `page`, `limit`
  - `fromTimestamp`, `toTimestamp`

**GET /api/public/sessions/{sessionId}**
- Get specific session details
- Can include all traces in session

### Observations API

**GET /api/public/observations**
- List observations with filters
- Parameters:
  - `page`, `limit`
  - `name` (string) - Observation name
  - `userId` (string)
  - `traceId` (string) - Filter by trace
  - `type` (string) - generation, span, event
  - `fromTimestamp`, `toTimestamp`

**GET /api/public/observations/{observationId}**
- Get specific observation details

### Metrics API

**GET /api/public/metrics**
- Most powerful endpoint for analytics
- Query parameter is a JSON string with structure:

```json
{
  "view": "traces|observations|scores-numeric|scores-categorical",
  "dimensions": [
    {"field": "name|userId|sessionId|model|..."}
  ],
  "metrics": [
    {
      "measure": "count|latency|value|tokens|cost",
      "aggregation": "count|sum|avg|p50|p95|p99|min|max|histogram"
    }
  ],
  "filters": [
    {
      "column": "string",
      "operator": "=|>|<|>=|<=|contains|startsWith",
      "value": "any",
      "type": "string|number|stringObject",
      "key": "string"  // for metadata filters
    }
  ],
  "timeDimension": {
    "granularity": "minute|hour|day|week|month|auto"
  },
  "fromTimestamp": "ISO 8601",
  "toTimestamp": "ISO 8601",
  "orderBy": [
    {
      "field": "string",
      "direction": "asc|desc"
    }
  ],
  "limit": 1000
}
```

### Scores API

**GET /api/public/scores**
- List scores with filters
- Parameters:
  - `page`, `limit`
  - `name` (string) - Score name
  - `fromTimestamp`, `toTimestamp`

**GET /api/public/scores/{scoreId}**
- Get specific score

## Dependencies

### Required Gems

```ruby
# langfuse-cli.gemspec
Gem::Specification.new do |spec|
  spec.name          = "langfuse-cli"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.summary       = "CLI tool for Langfuse telemetry data"
  spec.description   = "Command-line interface for querying and analyzing Langfuse LLM observability data"
  spec.license       = "MIT"

  # Runtime dependencies
  spec.add_dependency "thor", "~> 1.3"              # CLI framework
  spec.add_dependency "faraday", "~> 2.0"           # HTTP client
  spec.add_dependency "terminal-table", "~> 3.0"    # ASCII tables
  spec.add_dependency "tty-prompt", "~> 0.23"       # Interactive prompts
  spec.add_dependency "tty-table", "~> 0.12"        # Enhanced tables
  spec.add_dependency "tty-spinner", "~> 0.9"       # Loading spinners
  spec.add_dependency "colorize", "~> 1.1"          # Terminal colors
  spec.add_dependency "chronic", "~> 0.10"          # Natural language dates

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "vcr", "~> 6.2"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "byebug", "~> 11.1"
end
```

## Project Structure

```
langfuse-cli/
├── langfuse-cli.gemspec          # Gem specification
├── Gemfile                       # Bundle dependencies
├── Rakefile                      # Rake tasks
├── README.md                     # User documentation
├── LICENSE                       # MIT license
├── CHANGELOG.md                  # Version history
│
├── bin/
│   └── langfuse                  # Executable entry point
│
├── lib/
│   ├── langfuse_cli.rb          # Main require file
│   └── langfuse/
│       └── cli/
│           ├── version.rb        # Version constant
│           ├── cli.rb            # Main CLI class (Thor)
│           ├── client.rb         # API client
│           ├── config.rb         # Configuration management
│           │
│           ├── commands/         # Command modules
│           │   ├── base.rb       # Base command class
│           │   ├── traces.rb     # Traces commands
│           │   ├── sessions.rb   # Sessions commands
│           │   ├── observations.rb
│           │   ├── metrics.rb    # Metrics queries
│           │   ├── scores.rb     # Scores commands
│           │   └── tui.rb        # Terminal UI
│           │
│           ├── formatters/       # Output formatters
│           │   ├── base.rb       # Base formatter
│           │   ├── table.rb      # ASCII tables
│           │   ├── json.rb       # JSON output
│           │   ├── csv.rb        # CSV export
│           │   ├── markdown.rb   # Markdown tables
│           │   └── tui.rb        # Terminal UI renderer
│           │
│           └── utils/            # Utilities
│               ├── time_parser.rb   # Parse relative timestamps
│               ├── filter_parser.rb # Parse filter expressions
│               └── paginator.rb     # Handle pagination
│
├── spec/                         # RSpec tests
│   ├── spec_helper.rb
│   ├── fixtures/                 # VCR cassettes
│   ├── unit/
│   │   ├── client_spec.rb
│   │   ├── config_spec.rb
│   │   ├── formatters/
│   │   └── utils/
│   └── integration/
│       ├── traces_spec.rb
│       ├── sessions_spec.rb
│       ├── observations_spec.rb
│       └── metrics_spec.rb
│
└── examples/                     # Usage examples
    ├── basic_usage.sh
    ├── metrics_queries.sh
    └── export_data.sh
```

## Implementation Phases (TDD Approach)

### Phase 1: Foundation (Week 1)

**Goal:** Basic infrastructure and API client

**Tasks:**
1. Create gem scaffolding
   - Initialize gemspec
   - Set up directory structure
   - Configure RSpec with VCR

2. Implement API Client
   - HTTP client with Faraday
   - Basic Auth implementation
   - Error handling
   - Tests with VCR cassettes

3. Configuration Management
   - Load config from file/env
   - Save/update config
   - Profile support
   - Tests for config precedence

**Deliverables:**
- Working API client that can authenticate and make requests
- Configuration system with env vars and config file support
- Comprehensive unit tests

### Phase 2: Core Commands (Week 2)

**Goal:** Traces and Sessions commands with basic output

**Tasks:**
1. Implement Traces Commands
   - `traces list` with filters
   - `traces get` for specific trace
   - `traces search` functionality
   - Pagination support

2. Implement Sessions Commands
   - `sessions list`
   - `sessions show` with traces
   - `sessions stats`

3. Basic Formatters
   - Table formatter (terminal-table)
   - JSON formatter
   - Tests for formatting

**Deliverables:**
- Working `langfuse traces` and `langfuse sessions` commands
- Table and JSON output formats
- Integration tests with VCR

### Phase 3: Advanced Features (Week 3)

**Goal:** Metrics, Observations, Scores, and all formatters

**Tasks:**
1. Implement Observations Commands
   - `observations list` with filters
   - `observations get`

2. Implement Metrics Commands
   - `metrics query` with complex queries
   - Shortcut commands (usage, latency, errors)
   - Query builder for complex filters

3. Implement Scores Commands
   - `scores list`
   - `scores get`

4. Complete All Formatters
   - CSV export formatter
   - Markdown formatter
   - Tests for all formatters

**Deliverables:**
- All major commands implemented
- All output formats working
- Filter and query parsing utilities

### Phase 4: Terminal UI (Week 4)

**Goal:** Interactive terminal UI for browsing

**Tasks:**
1. Design TUI Layout
   - List view with navigation
   - Detail view for traces/sessions
   - Search and filter UI

2. Implement TUI Components
   - Main menu
   - Trace browser
   - Session browser
   - Observation viewer
   - Metrics dashboard

3. Interactive Features
   - Keyboard navigation
   - Search functionality
   - Real-time refresh
   - Export from TUI

**Deliverables:**
- Working `langfuse tui` command
- Interactive browsing of traces, sessions, observations
- Polish and UX improvements

### Phase 5: Polish & Documentation (Week 5)

**Goal:** Production-ready release

**Tasks:**
1. Documentation
   - Comprehensive README
   - Usage examples
   - API documentation
   - Man pages

2. Error Handling
   - Better error messages
   - Retry logic
   - Rate limiting handling

3. Performance
   - Optimize pagination
   - Cache frequently accessed data
   - Parallel requests where possible

4. Publishing
   - Release to RubyGems
   - Version tagging
   - Changelog

**Deliverables:**
- Published gem on RubyGems
- Complete documentation
- Example scripts

## Usage Examples for Codex/Claude Agent

### Scenario 1: Debug Recent Agent Failures

```bash
# List recent traces for your agent, show only failures
langfuse traces list \
  --name "claude_agent" \
  --from "1 hour ago" \
  --limit 20 \
  --format table \
  | grep -i "error"

# Get detailed trace with all observations
langfuse traces get abc123-def456-789 --format json --with-observations | jq
```

### Scenario 2: Monitor Agent Performance

```bash
# Get latency and cost metrics for the last 24 hours
langfuse metrics query \
  --view observations \
  --from "24 hours ago" \
  --to "now" \
  --dimensions name,model \
  --metrics count,latency:avg,latency:p95,tokens:sum,cost:sum \
  --filters 'name=claude_agent' \
  --format table

# Export hourly metrics to CSV for analysis
langfuse metrics query \
  --view observations \
  --from "7 days ago" \
  --granularity hour \
  --dimensions model \
  --metrics count,latency:avg,cost:sum \
  --format csv \
  --output agent-metrics-7days.csv
```

### Scenario 3: Analyze User Sessions

```bash
# List all sessions in the last week
langfuse sessions list \
  --from "7 days ago" \
  --format table

# Show specific session with all traces
langfuse sessions show session_123 \
  --with-traces \
  --format markdown > session-report.md

# Get session statistics
langfuse sessions stats session_123
```

### Scenario 4: Export Data for Analysis

```bash
# Export all traces from yesterday to JSON for processing
langfuse traces list \
  --from "yesterday 00:00" \
  --to "yesterday 23:59" \
  --limit 1000 \
  --format json \
  --output traces-yesterday.json

# Export scores to CSV for ML training
langfuse scores list \
  --from "30 days ago" \
  --format csv \
  --output scores-30days.csv
```

### Scenario 5: Real-time Monitoring

```bash
# Launch interactive TUI to browse live data
langfuse tui

# Within TUI:
# - Press 't' to view traces
# - Press 's' to view sessions
# - Press 'm' to view metrics dashboard
# - Press '/' to search
# - Press 'r' to refresh
# - Press 'q' to quit
```

### Scenario 6: Compare Agent Versions

```bash
# Compare metrics between two time periods
langfuse metrics query \
  --view observations \
  --from "2025-01-01" \
  --to "2025-01-15" \
  --dimensions name,metadata.version \
  --metrics count,latency:avg,cost:sum \
  --filters 'name=claude_agent' \
  --format table

# Export for detailed analysis
langfuse metrics query \
  --view observations \
  --from "2025-01-01" \
  --to "2025-01-20" \
  --dimensions metadata.version \
  --metrics count,latency:avg,latency:p50,latency:p95,cost:sum,tokens:sum \
  --format csv \
  --output version-comparison.csv
```

### Scenario 7: Quick Health Check

```bash
# Create a shell script for daily health check
#!/bin/bash

echo "=== Agent Health Check - $(date) ==="

echo "\n📊 Last Hour Stats:"
langfuse metrics query \
  --view observations \
  --from "1 hour ago" \
  --dimensions name \
  --metrics count,latency:avg \
  --filters 'name=claude_agent' \
  --format table

echo "\n❌ Recent Errors:"
langfuse traces list \
  --name "claude_agent" \
  --from "1 hour ago" \
  --format table \
  | grep -i "error\|fail"

echo "\n💰 Cost Today:"
langfuse metrics query \
  --view observations \
  --from "today 00:00" \
  --metrics cost:sum \
  --filters 'name=claude_agent' \
  --format json \
  | jq -r '.data[0].cost_sum'
```

## Configuration & Setup

### Installation

```bash
gem install langfuse-cli
```

### Initial Setup

```bash
# Option 1: Interactive setup
langfuse config setup
# Prompts for API keys and saves to ~/.langfuse/config.yml

# Option 2: Environment variables
export LANGFUSE_PUBLIC_KEY="pk_xxx"
export LANGFUSE_SECRET_KEY="sk_xxx"
export LANGFUSE_HOST="https://cloud.langfuse.com"

# Option 3: Manual config file
mkdir -p ~/.langfuse
cat > ~/.langfuse/config.yml <<EOF
default:
  host: https://cloud.langfuse.com
  public_key: pk_xxx
  secret_key: sk_xxx
EOF
```

### Multiple Profiles

```bash
# Create profiles for different environments
langfuse config set production \
  --public-key pk_prod_xxx \
  --secret-key sk_prod_xxx

langfuse config set development \
  --public-key pk_dev_xxx \
  --secret-key sk_dev_xxx

# Use specific profile
langfuse --profile production traces list

# Or with environment variable
export LANGFUSE_PROFILE=production
langfuse traces list
```

## Testing Strategy

### Unit Tests
- Test each class/module in isolation
- Mock external dependencies (HTTP calls)
- Fast execution (<100ms per test)
- High coverage (>90%)

### Integration Tests
- Test complete command flows
- Use VCR to record/replay HTTP interactions
- Test with real API responses
- Cover happy paths and error cases

### TDD Workflow
1. Write failing test first
2. Implement minimum code to pass
3. Refactor while keeping tests green
4. Repeat

### Example Test Structure

```ruby
# spec/unit/client_spec.rb
RSpec.describe Langfuse::CLI::Client do
  let(:client) do
    described_class.new(
      public_key: 'test_pk',
      secret_key: 'test_sk',
      host: 'https://test.langfuse.com'
    )
  end

  describe '#list_traces' do
    it 'fetches traces with filters', :vcr do
      traces = client.list_traces(
        from_timestamp: '2025-01-01T00:00:00Z',
        limit: 10
      )

      expect(traces).to be_an(Array)
      expect(traces.first).to have_key('id')
    end

    it 'handles pagination' do
      # Test pagination logic
    end
  end
end

# spec/integration/traces_spec.rb
RSpec.describe 'traces command' do
  it 'lists traces with table format', :vcr do
    output = run_command('langfuse traces list --limit 5 --format table')

    expect(output).to include('Trace ID')
    expect(output).to include('Name')
  end
end
```

## Performance Considerations

### Optimization Strategies

1. **Pagination**
   - Default limit: 50 items
   - Lazy loading for large datasets
   - Progress indicators for long operations

2. **Caching**
   - Cache frequently accessed data (sessions, trace metadata)
   - TTL-based invalidation
   - Optional flag to bypass cache

3. **Parallel Requests**
   - Fetch multiple pages concurrently
   - Use connection pooling
   - Respect rate limits

4. **Output Streaming**
   - Stream results as they arrive
   - Don't buffer entire result set
   - Support for piping to other commands

## Security Considerations

1. **API Key Storage**
   - Never commit keys to version control
   - Secure file permissions on config file (0600)
   - Support for credential managers (keychain, 1Password CLI)

2. **HTTPS Only**
   - Enforce HTTPS for all API calls
   - Validate SSL certificates
   - No fallback to HTTP

3. **Input Validation**
   - Sanitize all user inputs
   - Validate date formats
   - Prevent injection attacks

## Future Enhancements

### Phase 6+ (Future)
- **Webhooks**: Listen to real-time events
- **Alerts**: Set up alerts based on metrics
- **Dashboard**: Web-based dashboard served locally
- **Plugins**: Plugin system for custom commands
- **AI Assistant**: Natural language queries powered by LLM
- **Diff**: Compare traces/sessions side by side
- **Replay**: Replay traces for debugging
- **Export Formats**: Parquet, Avro, protocol buffers

## Success Metrics

### Week 1-2 (MVP)
- ✅ API client working with auth
- ✅ Traces and sessions commands
- ✅ Table and JSON output

### Week 3-4 (Feature Complete)
- ✅ All commands implemented
- ✅ All output formats working
- ✅ Terminal UI functional

### Week 5 (Launch)
- ✅ Published to RubyGems
- ✅ Documentation complete
- ✅ 10+ example scripts

### Post-Launch
- 100+ gem downloads in first month
- 5+ GitHub stars
- 0 critical bugs
- User feedback incorporated

## Risks & Mitigations

### Risk 1: API Changes
- **Mitigation**: Version lock OpenAPI spec, monitor changelog
- **Impact**: Medium
- **Probability**: Low

### Risk 2: Rate Limiting
- **Mitigation**: Implement exponential backoff, respect rate limits
- **Impact**: Medium
- **Probability**: Medium

### Risk 3: Large Datasets
- **Mitigation**: Streaming, pagination, progress indicators
- **Impact**: High
- **Probability**: High

### Risk 4: Authentication Issues
- **Mitigation**: Clear error messages, setup wizard, docs
- **Impact**: High
- **Probability**: Medium

## Conclusion

This plan provides a comprehensive roadmap for building a production-ready Langfuse CLI tool. The phased approach ensures we deliver value incrementally while maintaining high quality through TDD practices.

The tool will significantly improve the developer experience when working with Langfuse, making it easy to query, analyze, and export telemetry data directly from the command line.

Next step: Begin implementation with Phase 1 (Foundation) by creating the gem scaffolding and implementing the API client.
