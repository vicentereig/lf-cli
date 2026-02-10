require 'spec_helper'
require 'langfuse/cli/formatters/markdown_formatter'

RSpec.describe Langfuse::CLI::Formatters::MarkdownFormatter do
  describe '.format' do
    context 'with an array of hashes' do
      let(:data) do
        [
          { 'id' => '1', 'name' => 'trace1', 'value' => 100 },
          { 'id' => '2', 'name' => 'trace2', 'value' => 200 }
        ]
      end

      it 'formats data as a markdown table' do
        result = described_class.format(data)
        expect(result).to be_a(String)
        expect(result).to include('|')
        expect(result).to include('---')
      end

      it 'includes headers' do
        result = described_class.format(data)
        expect(result).to include('| id')
        expect(result).to include('| name')
        expect(result).to include('| value')
      end

      it 'includes separator row' do
        result = described_class.format(data)
        lines = result.split("\n")
        expect(lines[1]).to match(/\|\s*---/)
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

      it 'formats single item as markdown table' do
        result = described_class.format(data)
        expect(result).to be_a(String)
        expect(result).to include('trace1')
        expect(result).to include('|')
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

    context 'with pipe characters in data' do
      let(:data) do
        [
          { 'id' => '1', 'name' => 'trace | with | pipes' }
        ]
      end

      it 'escapes pipe characters' do
        result = described_class.format(data)
        # Pipes should be escaped in markdown table cells
        expect(result).to include('trace')
        expect(result).to include('pipes')
      end
    end

    context 'with multiline values' do
      let(:data) do
        [
          { 'id' => '1', 'output' => "line1\nline2" }
        ]
      end

      it 'normalizes newlines for valid markdown tables' do
        result = described_class.format(data)
        expect(result).to include('line1<br>line2')
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
