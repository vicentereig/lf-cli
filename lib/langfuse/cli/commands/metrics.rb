require 'thor'
require 'json'

module Langfuse
  module CLI
    module Commands
      class Metrics < Thor
        namespace :metrics

        def self.exit_on_failure?
          true
        end

        desc 'query', 'Query metrics with custom parameters'
        option :view, type: :string, required: true, desc: 'View type (traces, observations, scores-numeric, scores-categorical)'
        option :measure, type: :string, required: true, desc: 'Measure (count, latency, value, tokens, cost)'
        option :aggregation, type: :string, required: true, desc: 'Aggregation (count, sum, avg, p50, p95, p99, min, max, histogram)'
        option :dimensions, type: :array, desc: 'Dimensions to group by (e.g., name, userId, sessionId)'
        option :from, type: :string, desc: 'Start timestamp (ISO 8601 or relative)'
        option :to, type: :string, desc: 'End timestamp (ISO 8601 or relative)'
        option :granularity, type: :string, desc: 'Time granularity (minute, hour, day, week, month, auto)'
        option :limit, type: :numeric, desc: 'Limit number of results', default: 100
        def query
          query_params = build_query(options)
          result = client.query_metrics(query_params)

          # Extract data from result if it's wrapped in a data key
          output_data = result.is_a?(Hash) && result['data'] ? result['data'] : result
          output_result(output_data)
        rescue Client::AuthenticationError => e
          puts "Authentication Error: #{e.message}"
          exit 1
        rescue Client::APIError => e
          puts "Error: #{e.message}"
          exit 1
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
            format: parent_options[:format]
          )
        end

        def build_query(opts)
          query = {}

          # Required fields
          query['view'] = opts[:view]
          query['metrics'] = [
            {
              'measure' => opts[:measure],
              'aggregation' => opts[:aggregation]
            }
          ]

          # Optional dimensions
          if opts[:dimensions] && !opts[:dimensions].empty?
            query['dimensions'] = opts[:dimensions].map { |dim| { 'field' => dim } }
          end

          # Time range
          query['fromTimestamp'] = parse_timestamp(opts[:from]) if opts[:from]
          query['toTimestamp'] = parse_timestamp(opts[:to]) if opts[:to]

          # Time dimension
          if opts[:granularity]
            query['timeDimension'] = { 'granularity' => opts[:granularity] }
          end

          # Limit
          query['limit'] = opts[:limit] if opts[:limit]

          query
        end

        def parse_timestamp(timestamp)
          return timestamp if timestamp.is_a?(String) && timestamp.match?(/^\d{4}-\d{2}-\d{2}T/)

          # Try to parse with chronic if available
          begin
            require 'chronic'
            parsed = Chronic.parse(timestamp)
            parsed&.iso8601
          rescue LoadError
            timestamp
          end
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
      end
    end
  end
end
