require 'spec_helper'
require 'langfuse/cli/formatters/table_formatter'

RSpec.describe Langfuse::CLI::Formatters::TableFormatter do
  describe '.format' do
    context 'with an array of hashes' do
      let(:data) do
        [
          { 'id' => '1', 'name' => 'trace1', 'timestamp' => '2024-01-01T00:00:00Z' },
          { 'id' => '2', 'name' => 'trace2', 'timestamp' => '2024-01-02T00:00:00Z' }
        ]
      end

      it 'formats data as a table' do
        result = described_class.format(data)
        expect(result).to be_a(String)
        expect(result).to include('id')
        expect(result).to include('name')
        expect(result).to include('timestamp')
        expect(result).to include('trace1')
        expect(result).to include('trace2')
      end

      it 'includes table borders' do
        result = described_class.format(data)
        expect(result).to match(/[+\-|]/)  # Table has borders
      end
    end

    context 'with an empty array' do
      it 'returns a message indicating no data' do
        result = described_class.format([])
        expect(result).to include('No data')
      end
    end

    context 'with a single hash' do
      let(:data) do
        { 'id' => '1', 'name' => 'trace1', 'timestamp' => '2024-01-01T00:00:00Z' }
      end

      it 'formats single item as a table' do
        result = described_class.format(data)
        expect(result).to be_a(String)
        expect(result).to include('trace1')
      end
    end

    context 'with nested data' do
      let(:data) do
        [
          { 'id' => '1', 'metadata' => { 'key' => 'value' } }
        ]
      end

      it 'handles nested hashes by converting to string' do
        result = described_class.format(data)
        expect(result).to be_a(String)
        expect(result).to include('metadata')
      end
    end

    context 'with nil values' do
      let(:data) do
        [
          { 'id' => '1', 'name' => nil, 'value' => 'test' }
        ]
      end

      it 'handles nil values gracefully' do
        result = described_class.format(data)
        expect(result).to be_a(String)
        expect(result).to include('test')
      end
    end

    context 'with very large values' do
      let(:data) do
        [
          { 'id' => '1', 'payload' => 'a' * 5000 }
        ]
      end

      it 'truncates large cell values by default' do
        result = described_class.format(data)
        expect(result).to include('[truncated')
      end
    end
  end
end
