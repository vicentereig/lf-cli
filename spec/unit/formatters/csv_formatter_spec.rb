require 'spec_helper'
require 'langfuse/cli/formatters/csv_formatter'
require 'csv'

RSpec.describe Langfuse::CLI::Formatters::CSVFormatter do
  describe '.format' do
    context 'with an array of hashes' do
      let(:data) do
        [
          { 'id' => '1', 'name' => 'trace1', 'value' => 100 },
          { 'id' => '2', 'name' => 'trace2', 'value' => 200 }
        ]
      end

      it 'formats data as CSV' do
        result = described_class.format(data)
        expect(result).to be_a(String)

        # Parse the CSV to verify structure
        parsed = CSV.parse(result, headers: true)
        expect(parsed.headers).to contain_exactly('id', 'name', 'value')
        expect(parsed.length).to eq(2)
      end

      it 'includes headers in the first row' do
        result = described_class.format(data)
        lines = result.split("\n")
        expect(lines.first).to include('id', 'name', 'value')
      end

      it 'includes all data rows' do
        result = described_class.format(data)
        expect(result).to include('trace1')
        expect(result).to include('trace2')
        expect(result).to include('100')
        expect(result).to include('200')
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
        { 'id' => '1', 'name' => 'trace1' }
      end

      it 'formats single item as CSV' do
        result = described_class.format(data)
        expect(result).to be_a(String)
        expect(result).to include('trace1')
      end
    end

    context 'with nil values' do
      let(:data) do
        [
          { 'id' => '1', 'name' => nil, 'value' => 'test' }
        ]
      end

      it 'handles nil values as empty strings' do
        result = described_class.format(data)
        parsed = CSV.parse(result, headers: true)
        expect(parsed.first['name']).to eq('')
      end
    end

    context 'with special characters' do
      let(:data) do
        [
          { 'id' => '1', 'name' => 'trace, with comma', 'value' => 'quote"test' }
        ]
      end

      it 'properly escapes special characters' do
        result = described_class.format(data)
        parsed = CSV.parse(result, headers: true)
        expect(parsed.first['name']).to eq('trace, with comma')
        expect(parsed.first['value']).to eq('quote"test')
      end
    end

    context 'with nested data' do
      let(:data) do
        [
          { 'id' => '1', 'metadata' => { 'key' => 'value' } }
        ]
      end

      it 'converts nested structures to JSON strings' do
        result = described_class.format(data)
        expect(result).to include('metadata')
        expect(result).to include('key')
      end
    end
  end
end
