require 'thor'
require_relative 'cli/version'
require_relative 'cli/config'
require_relative 'cli/client'
require_relative 'cli/commands/traces'
require_relative 'cli/commands/sessions'
require_relative 'cli/commands/observations'
require_relative 'cli/commands/scores'
require_relative 'cli/commands/metrics'
require_relative 'cli/commands/config'

module Langfuse
  module CLI

    class Main < Thor
      class << self
        def exit_on_failure?
          true
        end
      end

      # Global options that apply to all commands
      class_option :profile,
                   type: :string,
                   aliases: '-P',
                   desc: 'Config profile to use'
      class_option :format,
                   type: :string,
                   aliases: '-f',
                   enum: %w[table json csv markdown],
                   default: 'table',
                   desc: 'Output format'
      class_option :output,
                   type: :string,
                   aliases: '-o',
                   desc: 'Output file path (defaults to stdout)'
      class_option :limit,
                   type: :numeric,
                   aliases: '-l',
                   desc: 'Limit number of results'
      class_option :page,
                   type: :numeric,
                   aliases: '-p',
                   desc: 'Page number for pagination'
      class_option :host,
                   type: :string,
                   desc: 'Langfuse host URL'
      class_option :public_key,
                   type: :string,
                   desc: 'Langfuse public key'
      class_option :secret_key,
                   type: :string,
                   desc: 'Langfuse secret key'
      class_option :verbose,
                   type: :boolean,
                   aliases: '-v',
                   default: false,
                   desc: 'Verbose output'
      class_option :no_color,
                   type: :boolean,
                   default: false,
                   desc: 'Disable colored output'

      desc 'version', 'Show version'
      def version
        puts "langfuse-cli version #{Langfuse::CLI::VERSION}"
      end

      desc 'traces SUBCOMMAND ...ARGS', 'Manage traces'
      subcommand 'traces', Commands::Traces

      desc 'sessions SUBCOMMAND ...ARGS', 'Manage sessions'
      subcommand 'sessions', Commands::Sessions

      desc 'observations SUBCOMMAND ...ARGS', 'Manage observations'
      subcommand 'observations', Commands::Observations

      desc 'metrics SUBCOMMAND ...ARGS', 'Query metrics'
      subcommand 'metrics', Commands::Metrics

      desc 'scores SUBCOMMAND ...ARGS', 'Manage scores'
      subcommand 'scores', Commands::Scores

      desc 'config SUBCOMMAND ...ARGS', 'Manage configuration'
      subcommand 'config', Commands::ConfigCommand

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
          profile: options[:profile],
          public_key: options[:public_key],
          secret_key: options[:secret_key],
          host: options[:host],
          format: options[:format],
          limit: options[:limit]
        )
      end

      def output_result(data)
        formatted = format_output(data)

        if options[:output]
          File.write(options[:output], formatted)
          puts "Output written to #{options[:output]}" if options[:verbose]
        else
          puts formatted
        end
      end

      def format_output(data)
        case options[:format]
        when 'json'
          require 'json'
          JSON.pretty_generate(data)
        when 'csv'
          # CSV formatting will be implemented in formatters
          require_relative 'cli/formatters/csv_formatter'
          Formatters::CSVFormatter.format(data)
        when 'markdown'
          require_relative 'cli/formatters/markdown_formatter'
          Formatters::MarkdownFormatter.format(data)
        else # table
          require_relative 'cli/formatters/table_formatter'
          Formatters::TableFormatter.format(data)
        end
      end
    end
  end
end
