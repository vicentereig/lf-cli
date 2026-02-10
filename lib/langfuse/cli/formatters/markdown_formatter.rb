require 'json'
require 'date'
require 'sorbet-runtime'

module Langfuse
  module CLI
    module Formatters
      class MarkdownFormatter
        extend T::Sig

        DEFAULT_MAX_CELL_BYTES = 2048

        sig { params(data: T.untyped, max_cell_bytes: Integer).returns(String) }
        def self.format(data, max_cell_bytes: DEFAULT_MAX_CELL_BYTES)
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
            values = headers.map { |header| escape_pipes(format_value(row[header], max_cell_bytes: max_cell_bytes)) }
            output << "| #{values.join(' | ')} |"
          end

          output.join("\n")
        end

        private

        sig { params(value: T.untyped, max_cell_bytes: Integer).returns(String) }
        def self.format_value(value, max_cell_bytes:)
          case value
          when nil
            ''
          when Hash, Array
            normalize(truncate(value.to_json, max_cell_bytes))
          when Time, DateTime
            normalize(truncate(value.iso8601, max_cell_bytes))
          else
            normalize(truncate(value.to_s, max_cell_bytes))
          end
        end

        sig { params(str: String).returns(String) }
        def self.escape_pipes(str)
          # Escape pipe characters for markdown tables
          str.gsub('|', '\\|')
        end

        sig { params(value: String, max_cell_bytes: Integer).returns(String) }
        def self.truncate(value, max_cell_bytes)
          return value if value.bytesize <= max_cell_bytes

          visible = value.byteslice(0, max_cell_bytes)
          "#{visible}...[truncated #{value.bytesize - max_cell_bytes} bytes]"
        end

        sig { params(value: String).returns(String) }
        def self.normalize(value)
          value.gsub(/\r\n?|\n/, '<br>')
        end
      end
    end
  end
end
