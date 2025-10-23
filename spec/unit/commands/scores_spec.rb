require 'spec_helper'
require 'langfuse/cli/commands/scores'
require 'langfuse/cli/config'
require 'langfuse/cli/client'

RSpec.describe Langfuse::CLI::Commands::Scores do
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
    let(:scores_data) do
      [
        { 'id' => 'score1', 'name' => 'quality', 'value' => 0.95 },
        { 'id' => 'score2', 'name' => 'accuracy', 'value' => 0.88 }
      ]
    end

    before do
      allow(client).to receive(:list_scores).and_return(scores_data)
    end

    it 'calls the client with default filters' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_scores).with({})
      expect { command.list }.to output.to_stdout
    end

    it 'calls the client with filter options' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        name: 'quality',
        limit: 10
      })
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:list_scores).with(hash_including(
        name: 'quality',
        limit: 10
      ))
      expect { command.list }.to output.to_stdout
    end
  end

  describe '#get' do
    let(:score_data) do
      {
        'id' => 'score123',
        'name' => 'quality',
        'value' => 0.95
      }
    end

    before do
      allow(client).to receive(:get_score).and_return(score_data)
    end

    it 'calls the client with score ID' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:parent_options).and_return({})

      expect(client).to receive(:get_score).with('score123')
      expect { command.get('score123') }.to output.to_stdout
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
