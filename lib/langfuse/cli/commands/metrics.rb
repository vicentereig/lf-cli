require 'thor'
require 'json'
require 'sorbet-runtime'
require_relative '../types'

module Langfuse
  module CLI
    module Commands
      class Metrics < Thor
        extend T::Sig
        namespace :metrics

        def self.exit_on_failure?
          true
        end

        desc 'query', 'Query metrics with custom parameters'
        long_desc <<-LONGDESC
          Query Langfuse metrics with flexible aggregations and dimensions.

          REQUIRED OPTIONS:
            --view: View type to query
              Valid values: traces, observations, scores-numeric, scores-categorical

            --measure: Metric to measure
              Valid values: count, latency, value, tokens, cost

            --aggregation: How to aggregate the measure
              Valid values: count, sum, avg, p50, p95, p99, min, max, histogram

          OPTIONAL:
            --dimensions: Fields to group by (repeatable)
              Examples: name, userId, sessionId, model, type

            --from, --to: Time range (ISO 8601 or relative like "1 hour ago")

            --granularity: Time bucketing
              Valid values: minute, hour, day, week, month, auto

          EXAMPLES:

            # Count all traces
            lf metrics query --view traces --measure count --aggregation count

            # Average latency by trace name
            lf metrics query --view observations --measure latency --aggregation avg --dimensions name

            # Token usage with time range
            lf metrics query --view observations --measure tokens --aggregation sum --from "2024-01-01" --to "2024-12-31"

            # P95 latency grouped by model
            lf metrics query --view observations --measure latency --aggregation p95 --dimensions model

          API REFERENCE:
            Full API documentation: https://api.reference.langfuse.com/
            OpenAPI spec: https://cloud.langfuse.com/generated/api/openapi.yml
        LONGDESC
        option :view, type: :string, required: true,
               enum: %w[traces observations scores-numeric scores-categorical],
               desc: 'View type'
        option :measure, type: :string, required: true,
               enum: %w[count latency value tokens cost],
               desc: 'Measure type'
        option :aggregation, type: :string, required: true,
               enum: %w[count sum avg p50 p95 p99 min max histogram],
               desc: 'Aggregation function'
        option :dimensions, type: :array, desc: 'Fields to group by (e.g., name userId sessionId model)'
        option :from, type: :string, desc: 'Start timestamp (ISO 8601 or relative)'
        option :to, type: :string, desc: 'End timestamp (ISO 8601 or relative)'
        option :granularity, type: :string,
               enum: %w[minute hour day week month auto],
               desc: 'Time granularity'
        option :limit, type: :numeric, desc: 'Limit number of results', default: 100
        def query
          query_params = build_query(options)
          result = client.query_metrics(query_params)

          # Extract data from result if it's wrapped in a data key
          output_data = result.is_a?(Hash) && result['data'] ? result['data'] : result
          output_result(output_data)
        rescue Client::AuthenticationError => e
          raise_cli_error("Authentication Error: #{e.message}")
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
            format: parent_options[:format]
          )
        end

        sig { params(opts: T::Hash[Symbol, T.untyped]).returns(T::Hash[String, T.untyped]) }
        def build_query(opts)
          # Validate enum values
          Types::MetricsView.deserialize(opts[:view])
          Types::Measure.deserialize(opts[:measure])
          Types::Aggregation.deserialize(opts[:aggregation])
          Types::TimeGranularity.deserialize(opts[:granularity]) if opts[:granularity]

          # Build query using struct
          query = Types::MetricsQuery.new(
            view: opts[:view],
            measure: opts[:measure],
            aggregation: opts[:aggregation],
            dimensions: opts[:dimensions],
            from_timestamp: opts[:from] ? parse_timestamp(opts[:from]) : nil,
            to_timestamp: opts[:to] ? parse_timestamp(opts[:to]) : nil,
            granularity: opts[:granularity],
            limit: opts[:limit]
          )

          query.to_h
        end

        sig { params(timestamp: String).returns(T.nilable(String)) }
        def parse_timestamp(timestamp)
          return timestamp if timestamp.match?(/^\d{4}-\d{2}-\d{2}T/)

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
