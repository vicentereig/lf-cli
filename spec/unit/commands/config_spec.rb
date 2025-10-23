require 'spec_helper'
require 'langfuse/cli/commands/config'
require 'langfuse/cli/config'
require 'langfuse/cli/client'

RSpec.describe Langfuse::CLI::Commands::ConfigCommand do
  let(:config) do
    Langfuse::CLI::Config.new(
      public_key: 'test_public_key',
      secret_key: 'test_secret_key',
      host: 'https://test.langfuse.com'
    )
  end

  let(:client) { instance_double(Langfuse::CLI::Client) }
  let(:prompt) { instance_double(TTY::Prompt) }

  before do
    allow(TTY::Prompt).to receive(:new).and_return(prompt)
    allow(Langfuse::CLI::Client).to receive(:new).and_return(client)
  end

  describe '#setup' do
    it 'prompts for project name, credentials, and saves config' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})

      # Mock prompts
      expect(prompt).to receive(:ask)
        .with('Enter your Langfuse project name:', required: true)
        .and_return('my-project')

      expect(prompt).to receive(:say)
        .with(/Opening browser/)

      expect(prompt).to receive(:say)
        .with(/Or visit manually/)

      expect(command).to receive(:open_browser)
        .with('https://cloud.langfuse.com/project/my-project/settings')

      expect(prompt).to receive(:ask)
        .with('Enter your Langfuse public key:', required: true)
        .and_return('pk_test')

      expect(prompt).to receive(:mask)
        .with('Enter your Langfuse secret key:', required: true)
        .and_return('sk_test')

      expect(prompt).to receive(:ask)
        .with('Enter host:', default: 'https://cloud.langfuse.com')
        .and_return('https://cloud.langfuse.com')

      expect(prompt).to receive(:ask)
        .with('Save as profile name:', default: 'default')
        .and_return('default')

      # Mock connection test
      expect(client).to receive(:list_traces).with(limit: 1).and_return([])

      expect(prompt).to receive(:ok).with('Testing connection... Success!')
      expect(prompt).to receive(:ok).with(/Configuration saved/)

      # Mock config save
      mock_config = instance_double(Langfuse::CLI::Config)
      allow(Langfuse::CLI::Config).to receive(:new).and_return(mock_config)
      expect(mock_config).to receive(:save).with('default').and_return(true)

      expect { command.setup }.to output.to_stdout
    end

    it 'handles connection test failures gracefully' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})
      allow(command).to receive(:exit) # Stub exit to prevent test from exiting

      expect(prompt).to receive(:ask)
        .with('Enter your Langfuse project name:', required: true)
        .and_return('my-project')

      expect(prompt).to receive(:say).twice
      expect(command).to receive(:open_browser)

      expect(prompt).to receive(:ask)
        .with('Enter your Langfuse public key:', required: true)
        .and_return('pk_test')

      expect(prompt).to receive(:mask)
        .with('Enter your Langfuse secret key:', required: true)
        .and_return('sk_test')

      expect(prompt).to receive(:ask)
        .with('Enter host:', default: 'https://cloud.langfuse.com')
        .and_return('https://cloud.langfuse.com')

      expect(prompt).to receive(:ask)
        .with('Save as profile name:', default: 'default')
        .and_return('default')

      expect(client).to receive(:list_traces)
        .and_raise(Langfuse::CLI::Client::AuthenticationError, 'Invalid credentials')

      expect(prompt).to receive(:error).with(/Connection test failed/)
      expect(prompt).to receive(:error).with(/Please check your credentials/)

      expect { command.setup }.to output.to_stdout
    end
  end

  describe '#show' do
    it 'displays configuration for a profile' do
      command = described_class.new
      allow(command).to receive(:options).and_return({})

      mock_config = instance_double(Langfuse::CLI::Config)
      allow(Langfuse::CLI::Config).to receive(:new).and_return(mock_config)
      allow(mock_config).to receive(:public_key).and_return('pk_xxx')
      allow(mock_config).to receive(:secret_key).and_return('sk_xxx')
      allow(mock_config).to receive(:host).and_return('https://cloud.langfuse.com')
      allow(mock_config).to receive(:output_format).and_return('table')
      allow(mock_config).to receive(:page_limit).and_return(50)

      output = capture_stdout { command.show('default') }
      expect(output).to include('Configuration for profile: default')
      expect(output).to include('pk_xxx')
      expect(output).to include('cloud.langfuse.com')
    end
  end

  describe '#set' do
    it 'sets configuration values for a profile' do
      command = described_class.new
      allow(command).to receive(:options).and_return({
        public_key: 'pk_new',
        secret_key: 'sk_new',
        host: 'https://custom.langfuse.com'
      })

      mock_config = instance_double(Langfuse::CLI::Config)
      allow(Langfuse::CLI::Config).to receive(:new).and_return(mock_config)
      expect(mock_config).to receive(:save).with('production').and_return(true)

      expect(prompt).to receive(:ok).with(/Configuration saved for profile: production/)

      command.set('production')
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
