require 'terminal-table'
require 'date'
require 'sorbet-runtime'

module Langfuse
  module CLI
    module Formatters
      class TableFormatter
        extend T::Sig

        DEFAULT_MAX_CELL_BYTES = 2048

        sig { params(data: T.untyped, max_cell_bytes: Integer).returns(String) }
        def self.format(data, max_cell_bytes: DEFAULT_MAX_CELL_BYTES)
          return "No data to display" if data.nil? || (data.is_a?(Array) && data.empty?)

          # Convert single hash to array for consistent handling
          data = [data] unless data.is_a?(Array)

          # Get all unique keys from all rows
          headers = data.flat_map(&:keys).uniq

          # Build rows
          rows = data.map do |row|
            headers.map { |header| format_value(row[header], max_cell_bytes: max_cell_bytes) }
          end

          # Create table
          table = Terminal::Table.new(headings: headers, rows: rows)
          table.to_s
        end

        private

        sig { params(value: T.untyped, max_cell_bytes: Integer).returns(String) }
        def self.format_value(value, max_cell_bytes:)
          case value
          when nil
            ''
          when Hash, Array
            truncate(value.to_json, max_cell_bytes)
          when Time, DateTime
            truncate(value.iso8601, max_cell_bytes)
          else
            truncate(value.to_s, max_cell_bytes)
          end
        end

        sig { params(value: String, max_cell_bytes: Integer).returns(String) }
        def self.truncate(value, max_cell_bytes)
          return value if value.bytesize <= max_cell_bytes

          visible = value.byteslice(0, max_cell_bytes)
          "#{visible}...[truncated #{value.bytesize - max_cell_bytes} bytes]"
        end
      end
    end
  end
end
