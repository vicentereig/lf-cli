require 'thor'

module Langfuse
  module CLI
    module Commands
      class Observations < Thor
        namespace :observations

        def self.exit_on_failure?
          true
        end

        desc 'list', 'List observations'
        long_desc <<-LONGDESC
          List observations with optional filtering.

          Observations represent LLM calls, spans, or events in your traces.

          FILTERS:
            --type: Observation type
              Valid values: generation, span, event

            --trace-id: Filter by parent trace ID

            --name: Filter by observation name

            --user-id: Filter by user ID

            --from, --to: Time range (ISO 8601 or relative like "1 hour ago")

          EXAMPLES:

            # List all generations
            langfuse observations list --type generation

            # List observations for a specific trace
            langfuse observations list --trace-id trace_123

            # List recent observations
            langfuse observations list --from "1 hour ago" --limit 20

          API REFERENCE:
            Full API documentation: https://api.reference.langfuse.com/
        LONGDESC
        option :trace_id, type: :string, desc: 'Filter by trace ID'
        option :name, type: :string, desc: 'Filter by observation name'
        option :type, type: :string,
               enum: %w[generation span event],
               desc: 'Filter by type'
        option :user_id, type: :string, desc: 'Filter by user ID'
        option :from, type: :string, desc: 'Start timestamp (ISO 8601 or relative)'
        option :to, type: :string, desc: 'End timestamp (ISO 8601 or relative)'
        option :limit, type: :numeric, desc: 'Limit number of results'
        option :page, type: :numeric, desc: 'Page number'
        def list
          filters = build_filters(options)
          observations = client.list_observations(filters)
          output_result(observations)
        rescue Client::AuthenticationError => e
          raise_cli_error("Authentication Error: #{e.message}")
        rescue Client::APIError => e
          raise_cli_error("Error: #{e.message}")
        end

        desc 'get OBSERVATION_ID', 'Get a specific observation'
        def get(observation_id)
          observation = client.get_observation(observation_id)
          output_result(observation)
        rescue Client::NotFoundError
          raise_cli_error("Observation not found - #{observation_id}")
        rescue Client::APIError => e
          raise_cli_error("Error: #{e.message}")
        end

        private

        def client
          @client ||= begin
            config = load_config
            unless config.valid?
              error_message = "Missing required configuration: #{config.missing_fields.join(', ')}"
              error_message += "\n\nPlease set environment variables or run: langfuse config setup"
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
          filters[:trace_id] = opts[:trace_id] if opts[:trace_id]
          filters[:name] = opts[:name] if opts[:name]
          filters[:type] = opts[:type] if opts[:type]
          filters[:user_id] = opts[:user_id] if opts[:user_id]
          filters[:from] = opts[:from] if opts[:from]
          filters[:to] = opts[:to] if opts[:to]
          filters[:limit] = opts[:limit] if opts[:limit]
          filters[:page] = opts[:page] if opts[:page]
          filters
        end

        def output_result(data)
          formatted = format_output(data)

          if parent_options[:output]
            File.write(parent_options[:output], formatted)
            puts "Output written to #{parent_options[:output]}" if parent_options[:verbose]
          else
            puts formatted
          end
        end

        def format_output(data)
          format_type = parent_options[:format] || 'table'

          case format_type
          when 'json'
            require 'json'
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

        def parent_options
          @parent_options ||= begin
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
