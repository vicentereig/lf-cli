require 'terminal-table'

module Langfuse
  module CLI
    module Formatters
      class TableFormatter
        def self.format(data)
          return "No data to display" if data.nil? || (data.is_a?(Array) && data.empty?)

          # Convert single hash to array for consistent handling
          data = [data] unless data.is_a?(Array)

          # Get all unique keys from all rows
          headers = data.flat_map(&:keys).uniq

          # Build rows
          rows = data.map do |row|
            headers.map { |header| format_value(row[header]) }
          end

          # Create table
          table = Terminal::Table.new(headings: headers, rows: rows)
          table.to_s
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
      end
    end
  end
end
