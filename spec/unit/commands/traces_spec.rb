require 'spec_helper'
require 'langfuse/cli/commands/traces'
require 'langfuse/cli/config'
require 'langfuse/cli/client'

RSpec.describe Langfuse::CLI::Commands::Traces do
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

  describe '#list' do
    let(:traces_data) do
      [
        { 'id' => '1', 'name' => 'trace1', 'timestamp' => '2024-01-01T00:00:00Z' },
        { 'id' => '2', 'name' => 'trace2', 'timestamp' => '2024-01-02T00:00:00Z' }
      ]
    end

    before do
      allow(client).to receive(:list_traces).and_return(traces_data)
    end

    it 'calls the client with default filters' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_traces).with({})
      expect { command.list }.to output.to_stdout
    end

    it 'calls the client with filter options' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        name: 'test_trace',
        from: '2024-01-01',
        to: '2024-12-31',
        limit: 10
      })
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_traces).with(hash_including(
        name: 'test_trace',
        from: '2024-01-01',
        to: '2024-12-31',
        limit: 10
      ))
      expect { command.list }.to output.to_stdout
    end

    it 'outputs formatted results' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({ format: 'table' })

      output = capture_stdout { command.list }
      expect(output).to include('trace1')
      expect(output).to include('trace2')
    end
  end

  describe '#get' do
    let(:trace_data) do
      {
        'id' => '123',
        'name' => 'test_trace',
        'timestamp' => '2024-01-01T00:00:00Z',
        'observations' => []
      }
    end

    before do
      allow(client).to receive(:get_trace).and_return(trace_data)
    end

    it 'calls the client with trace ID' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:get_trace).with('123')
      expect { command.get('123') }.to output.to_stdout
    end

    it 'outputs formatted trace details' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({ format: 'table' })

      output = capture_stdout { command.get('123') }
      expect(output).to include('test_trace')
    end
  end

  describe 'error handling' do
    it 'handles API errors gracefully' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})
      allow(client).to receive(:list_traces).and_raise(Langfuse::CLI::Client::APIError, 'API Error')

      expect { command.list }.to output(/Error/).to_stdout
    end

    it 'handles authentication errors' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})
      allow(client).to receive(:list_traces).and_raise(Langfuse::CLI::Client::AuthenticationError, 'Auth failed')

      expect { command.list }.to output(/Auth/).to_stdout
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
