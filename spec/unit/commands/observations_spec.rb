require 'spec_helper'
require 'langfuse/cli/commands/observations'
require 'langfuse/cli/config'
require 'langfuse/cli/client'

RSpec.describe Langfuse::CLI::Commands::Observations do
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
    let(:observations_data) do
      [
        { 'id' => 'obs1', 'name' => 'generation1', 'type' => 'generation' },
        { 'id' => 'obs2', 'name' => 'span1', 'type' => 'span' }
      ]
    end

    before do
      allow(client).to receive(:list_observations).and_return(observations_data)
    end

    it 'calls the client with default filters' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_observations).with({})
      expect { command.list }.to output.to_stdout
    end

    it 'calls the client with filter options' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        trace_id: 'trace123',
        type: 'generation',
        limit: 10
      })
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_observations).with(hash_including(
        trace_id: 'trace123',
        type: 'generation',
        limit: 10
      ))
      expect { command.list }.to output.to_stdout
    end
  end

  describe '#get' do
    let(:observation_data) do
      {
        'id' => 'obs123',
        'name' => 'test_observation',
        'type' => 'generation'
      }
    end

    before do
      allow(client).to receive(:get_observation).and_return(observation_data)
    end

    it 'calls the client with observation ID' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:get_observation).with('obs123')
      expect { command.get('obs123') }.to output.to_stdout
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
