require 'thor'
require 'json'

module Langfuse
  module CLI
    module Commands
      class Traces < Thor
        namespace :traces

        def self.exit_on_failure?
          true
        end

        desc 'list', 'List traces'
        long_desc <<-LONGDESC
          List traces with optional filtering.

          Traces represent complete workflows or conversations in Langfuse.

          FILTERS:
            --name: Filter by trace name

            --user-id: Filter by user ID

            --session-id: Filter by session ID

            --tags: Filter by tags (repeatable)

            --from, --to: Time range (ISO 8601 or relative like "1 hour ago")

          OUTPUT OPTIONS:
            Global options: --format [table|json|csv|markdown], --output FILE

          EXAMPLES:

            # List recent traces
            lf traces list --from "1 hour ago" --limit 20

            # Find traces by name
            lf traces list --name "chat_completion"

            # Filter by user and session
            lf traces list --user-id user_123 --session-id sess_456

            # Export to CSV
            lf traces list --format csv --output traces.csv

          API REFERENCE:
            Full API documentation: https://api.reference.langfuse.com/
        LONGDESC
        option :from, type: :string, desc: 'Start timestamp (ISO 8601 or relative like "1 hour ago")'
        option :to, type: :string, desc: 'End timestamp (ISO 8601 or relative)'
        option :name, type: :string, desc: 'Filter by trace name'
        option :user_id, type: :string, desc: 'Filter by user ID'
        option :session_id, type: :string, desc: 'Filter by session ID'
        option :tags, type: :array, desc: 'Filter by tags'
        option :limit, type: :numeric, desc: 'Limit number of results'
        option :page, type: :numeric, desc: 'Page number'
        def list
          filters = build_filters(options)
          traces = client.list_traces(filters)
          output_result(traces)
        rescue Client::AuthenticationError => e
          raise_cli_error("Authentication Error: #{e.message}")
        rescue Client::APIError => e
          raise_cli_error("Error: #{e.message}")
        end

        desc 'get TRACE_ID', 'Get a specific trace'
        option :with_observations, type: :boolean, default: false, desc: 'Include all observations'
        def get(trace_id)
          trace = client.get_trace(trace_id)
          output_result(trace)
        rescue Client::NotFoundError => _e
          raise_cli_error("Trace not found - #{trace_id}")
        rescue Client::APIError => e
          raise_cli_error("Error: #{e.message}")
        end

        private

        def client
          @client ||= begin
            config = load_config
            unless config.valid?
              error_message = "Missing required configuration: #{config.missing_fields.join(', ')}"
              error_message += "\n\nPlease set environment variables or run: lf config setup"
              raise Error, error_message
            end
            Client.new(config)
          end
        end

        def load_config
          Config.new(
            profile: parent_options[:profile],
            public_key: parent_options[:public_key],
            secret_key: parent_options[:secret_key],
            host: parent_options[:host],
            format: parent_options[:format],
            limit: parent_options[:limit] || options[:limit]
          )
        end

        def build_filters(opts)
          filters = {}
          filters[:from] = opts[:from] if opts[:from]
          filters[:to] = opts[:to] if opts[:to]
          filters[:name] = opts[:name] if opts[:name]
          filters[:user_id] = opts[:user_id] if opts[:user_id]
          filters[:session_id] = opts[:session_id] if opts[:session_id]
          filters[:tags] = opts[:tags] if opts[:tags]
          filters[:limit] = opts[:limit] if opts[:limit]
          filters[:page] = opts[:page] if opts[:page]
          filters
        end

        def output_result(data)
          format_type = parent_options[:format] || 'table'

          if parent_options[:output]
            write_output(parent_options[:output], data, format_type)
            puts "Output written to #{parent_options[:output]}" if parent_options[:verbose]
          else
            puts format_output(data, format_type: format_type)
          end
        end

        def format_output(data, format_type: 'table')
          case format_type
          when 'json'
            JSON.pretty_generate(data)
          when 'csv'
            require_relative '../formatters/csv_formatter'
            Formatters::CSVFormatter.format(data)
          when 'markdown'
            require_relative '../formatters/markdown_formatter'
            Formatters::MarkdownFormatter.format(data)
          else # table
            require_relative '../formatters/table_formatter'
            Formatters::TableFormatter.format(data)
          end
        end

        def write_output(path, data, format_type)
          if format_type == 'json'
            File.open(path, 'w') { |file| JSON.dump(data, file) }
          else
            File.write(path, format_output(data, format_type: format_type))
          end
        end

        def parent_options
          @parent_options ||= begin
            # Try to get parent options from Thor
            if parent.respond_to?(:options)
              parent.options
            else
              {}
            end
          rescue
            {}
          end
        end

        def raise_cli_error(message)
          raise Langfuse::CLI::Error, message
        end
      end
    end
  end
end
