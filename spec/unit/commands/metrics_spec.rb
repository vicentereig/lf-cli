require 'spec_helper'
require 'langfuse/cli/commands/metrics'
require 'langfuse/cli/config'
require 'langfuse/cli/client'

RSpec.describe Langfuse::CLI::Commands::Metrics do
  let(:config) do
    Langfuse::CLI::Config.new(
      public_key: 'test_public_key',
      secret_key: 'test_secret_key',
      host: 'https://test.langfuse.com'
    )
  end

  let(:client) { instance_double(Langfuse::CLI::Client) }

  before do
    allow(Langfuse::CLI::Config).to receive(:new).and_return(config)
    allow(Langfuse::CLI::Client).to receive(:new).and_return(client)
  end

  describe '#query' do
    let(:metrics_result) do
      {
        'data' => [
          { 'name' => 'trace1', 'count' => 100 },
          { 'name' => 'trace2', 'count' => 50 }
        ]
      }
    end

    before do
      allow(client).to receive(:query_metrics).and_return(metrics_result)
    end

    it 'calls the client with a basic query' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        view: 'traces',
        measure: 'count',
        aggregation: 'count'
      })
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:query_metrics).with(hash_including(
        'view' => 'traces',
        'metrics' => [{ 'measure' => 'count', 'aggregation' => 'count' }]
      ))
      expect { command.query }.to output.to_stdout
    end

    it 'calls the client with dimensions' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        view: 'traces',
        measure: 'count',
        aggregation: 'count',
        dimensions: ['name', 'userId']
      })
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:query_metrics).with(hash_including(
        'view' => 'traces',
        'dimensions' => [{ 'field' => 'name' }, { 'field' => 'userId' }]
      ))
      expect { command.query }.to output.to_stdout
    end

    it 'calls the client with time range' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        view: 'traces',
        measure: 'count',
        aggregation: 'count',
        from: '2024-01-01T00:00:00Z',
        to: '2024-12-31T23:59:59Z'
      })
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:query_metrics).with(hash_including(
        'fromTimestamp' => '2024-01-01T00:00:00Z',
        'toTimestamp' => '2024-12-31T23:59:59Z'
      ))
      expect { command.query }.to output.to_stdout
    end

    it 'outputs formatted results' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        view: 'traces',
        measure: 'count',
        aggregation: 'count'
      })
      allow(command).to receive(:parent_options).and_return({ format: 'table' })

      output = capture_stdout { command.query }
      expect(output).to include('trace1')
      expect(output).to include('trace2')
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
