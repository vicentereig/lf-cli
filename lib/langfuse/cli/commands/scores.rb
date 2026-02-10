require 'thor'
require 'json'

module Langfuse
  module CLI
    module Commands
      class Scores < Thor
        namespace :scores

        def self.exit_on_failure?
          true
        end

        desc 'list', 'List scores'
        option :name, type: :string, desc: 'Filter by score name'
        option :from, type: :string, desc: 'Start timestamp (ISO 8601 or relative)'
        option :to, type: :string, desc: 'End timestamp (ISO 8601 or relative)'
        option :limit, type: :numeric, desc: 'Limit number of results'
        option :page, type: :numeric, desc: 'Page number'
        def list
          filters = build_filters(options)
          scores = client.list_scores(filters)
          output_result(scores)
        rescue Client::AuthenticationError => e
          raise_cli_error("Authentication Error: #{e.message}")
        rescue Client::APIError => e
          raise_cli_error("Error: #{e.message}")
        end

        desc 'get SCORE_ID', 'Get a specific score'
        def get(score_id)
          score = client.get_score(score_id)
          output_result(score)
        rescue Client::NotFoundError
          raise_cli_error("Score not found - #{score_id}")
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
          filters[:name] = opts[:name] if opts[:name]
          filters[:from] = opts[:from] if opts[:from]
          filters[:to] = opts[:to] if opts[:to]
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
