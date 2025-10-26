require 'spec_helper'
require 'langfuse/cli/commands/sessions'
require 'langfuse/cli/config'
require 'langfuse/cli/client'

RSpec.describe Langfuse::CLI::Commands::Sessions do
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
    let(:sessions_data) do
      [
        { 'id' => 'session1', 'createdAt' => '2024-01-01T00:00:00Z' },
        { 'id' => 'session2', 'createdAt' => '2024-01-02T00:00:00Z' }
      ]
    end

    before do
      allow(client).to receive(:list_sessions).and_return(sessions_data)
    end

    it 'calls the client with default filters' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_sessions).with({})
      expect { command.list }.to output.to_stdout
    end

    it 'calls the client with filter options' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        from: '2024-01-01',
        to: '2024-12-31',
        limit: 10
      })
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_sessions).with(hash_including(
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
      expect(output).to include('session1')
      expect(output).to include('session2')
    end
  end

  describe '#show' do
    let(:session_data) do
      {
        'id' => 'session123',
        'createdAt' => '2024-01-01T00:00:00Z',
        'traces' => []
      }
    end

    before do
      allow(client).to receive(:get_session).and_return(session_data)
    end

    it 'calls the client with session ID' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:get_session).with('session123')
      expect { command.show('session123') }.to output.to_stdout
    end

    it 'outputs formatted session details' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({ format: 'table' })

      output = capture_stdout { command.show('session123') }
      expect(output).to include('session123')
    end
  end

  describe 'error handling' do
    it 'handles API errors gracefully' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})
      allow(client).to receive(:list_sessions).and_raise(Langfuse::CLI::Client::APIError, 'API Error')

      expect { command.list }.to raise_error(Langfuse::CLI::Error, /API Error/)
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
