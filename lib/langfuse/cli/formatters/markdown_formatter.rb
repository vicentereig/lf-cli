require 'json'

module Langfuse
  module CLI
    module Formatters
      class MarkdownFormatter
        def self.format(data)
          return "No data to display" if data.nil? || (data.is_a?(Array) && data.empty?)

          # Convert single hash to array for consistent handling
          data = [data] unless data.is_a?(Array)

          # Get all unique keys from all rows
          headers = data.flat_map(&:keys).uniq

          # Build markdown table
          output = []

          # Header row
          output << "| #{headers.join(' | ')} |"

          # Separator row
          output << "| #{headers.map { '---' }.join(' | ')} |"

          # Data rows
          data.each do |row|
            values = headers.map { |header| escape_pipes(format_value(row[header])) }
            output << "| #{values.join(' | ')} |"
          end

          output.join("\n")
        end

        private

        def self.format_value(value)
          case value
          when nil
            ''
          when Hash, Array
            value.to_json
          when Time, DateTime
            value.iso8601
          else
            value.to_s
          end
        end

        def self.escape_pipes(str)
          # Escape pipe characters for markdown tables
          str.gsub('|', '\\|')
        end
      end
    end
  end
end
