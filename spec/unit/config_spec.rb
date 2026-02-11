require 'spec_helper'
require 'tempfile'
require 'fileutils'

RSpec.describe Langfuse::CLI::Config do
  let(:test_config_dir) { Dir.mktmpdir }
  let(:test_config_file) { File.join(test_config_dir, 'config.yml') }

  before do
    # Stub the constants to use test directory
    stub_const('Langfuse::CLI::Config::CONFIG_DIR', test_config_dir)
    stub_const('Langfuse::CLI::Config::CONFIG_FILE', test_config_file)

    # Clear environment variables
    ENV.delete('LANGFUSE_PUBLIC_KEY')
    ENV.delete('LANGFUSE_SECRET_KEY')
    ENV.delete('LANGFUSE_HOST')
    ENV.delete('LANGFUSE_PROFILE')
  end

  after do
    FileUtils.rm_rf(test_config_dir)
  end

  describe '#initialize' do
    context 'with no configuration' do
      it 'uses default values' do
        config = described_class.new

        expect(config.host).to eq('https://cloud.langfuse.com')
        expect(config.output_format).to eq('json')
        expect(config.page_limit).to eq(50)
        expect(config.public_key).to be_nil
        expect(config.secret_key).to be_nil
      end
    end

    context 'with environment variables' do
      before do
        ENV['LANGFUSE_PUBLIC_KEY'] = 'env_public_key'
        ENV['LANGFUSE_SECRET_KEY'] = 'env_secret_key'
        ENV['LANGFUSE_HOST'] = 'https://env.langfuse.com'
      end

      it 'loads from environment variables' do
        config = described_class.new

        expect(config.public_key).to eq('env_public_key')
        expect(config.secret_key).to eq('env_secret_key')
        expect(config.host).to eq('https://env.langfuse.com')
      end
    end

    context 'with config file' do
      before do
        config_data = {
          'default' => {
            'public_key' => 'file_public_key',
            'secret_key' => 'file_secret_key',
            'host' => 'https://file.langfuse.com',
            'output_format' => 'json',
            'page_limit' => 100
          }
        }
        File.write(test_config_file, config_data.to_yaml)
      end

      it 'loads from config file' do
        config = described_class.new

        expect(config.public_key).to eq('file_public_key')
        expect(config.secret_key).to eq('file_secret_key')
        expect(config.host).to eq('https://file.langfuse.com')
        expect(config.output_format).to eq('json')
        expect(config.page_limit).to eq(100)
      end
    end

    context 'with options parameter' do
      it 'uses passed options' do
        config = described_class.new(
          public_key: 'option_public_key',
          secret_key: 'option_secret_key',
          host: 'https://option.langfuse.com'
        )

        expect(config.public_key).to eq('option_public_key')
        expect(config.secret_key).to eq('option_secret_key')
        expect(config.host).to eq('https://option.langfuse.com')
      end
    end

    context 'with configuration precedence' do
      before do
        # Set up config file
        config_data = {
          'default' => {
            'public_key' => 'file_public_key',
            'secret_key' => 'file_secret_key',
            'host' => 'https://file.langfuse.com'
          }
        }
        File.write(test_config_file, config_data.to_yaml)

        # Set environment variables
        ENV['LANGFUSE_PUBLIC_KEY'] = 'env_public_key'
        ENV['LANGFUSE_HOST'] = 'https://env.langfuse.com'
      end

      it 'follows precedence: options > env > file > defaults' do
        config = described_class.new(
          public_key: 'option_public_key'
        )

        # Option overrides everything
        expect(config.public_key).to eq('option_public_key')

        # Env overrides file
        expect(config.host).to eq('https://env.langfuse.com')

        # File used when no env or option
        expect(config.secret_key).to eq('file_secret_key')
      end
    end

    context 'with profiles' do
      before do
        config_data = {
          'profiles' => {
            'default' => {
              'public_key' => 'default_public_key',
              'secret_key' => 'default_secret_key',
              'host' => 'https://default.langfuse.com'
            },
            'production' => {
              'public_key' => 'prod_public_key',
              'secret_key' => 'prod_secret_key',
              'host' => 'https://prod.langfuse.com'
            },
            'development' => {
              'public_key' => 'dev_public_key',
              'secret_key' => 'dev_secret_key',
              'host' => 'https://dev.langfuse.com'
            }
          }
        }
        File.write(test_config_file, config_data.to_yaml)
      end

      it 'loads specified profile' do
        config = described_class.new(profile: 'production')

        expect(config.public_key).to eq('prod_public_key')
        expect(config.secret_key).to eq('prod_secret_key')
        expect(config.host).to eq('https://prod.langfuse.com')
      end

      it 'loads profile from environment variable' do
        ENV['LANGFUSE_PROFILE'] = 'development'
        config = described_class.new

        expect(config.public_key).to eq('dev_public_key')
        expect(config.host).to eq('https://dev.langfuse.com')
      end

      it 'falls back to profiles.default when selected profile does not exist' do
        config = described_class.new(profile: 'missing-profile')

        expect(config.public_key).to eq('default_public_key')
        expect(config.secret_key).to eq('default_secret_key')
        expect(config.host).to eq('https://default.langfuse.com')
      end
    end
  end

  describe '#valid?' do
    it 'returns false when public_key is missing' do
      config = described_class.new(
        secret_key: 'test_secret',
        host: 'https://test.langfuse.com'
      )

      expect(config.valid?).to be false
    end

    it 'returns false when secret_key is missing' do
      config = described_class.new(
        public_key: 'test_public',
        host: 'https://test.langfuse.com'
      )

      expect(config.valid?).to be false
    end

    it 'returns false when credentials are blank strings' do
      config = described_class.new(
        public_key: '   ',
        secret_key: '',
        host: 'https://test.langfuse.com'
      )

      expect(config.valid?).to be false
    end

    it 'returns true when all required fields are present' do
      config = described_class.new(
        public_key: 'test_public',
        secret_key: 'test_secret',
        host: 'https://test.langfuse.com'
      )

      expect(config.valid?).to be true
    end
  end

  describe '#missing_fields' do
    it 'returns list of missing fields' do
      config = described_class.new

      missing = config.missing_fields
      expect(missing).to include('public_key')
      expect(missing).to include('secret_key')
    end

    it 'returns empty array when all fields present' do
      config = described_class.new(
        public_key: 'test_public',
        secret_key: 'test_secret',
        host: 'https://test.langfuse.com'
      )

      expect(config.missing_fields).to be_empty
    end

    it 'includes blank values as missing fields' do
      config = described_class.new(
        public_key: '',
        secret_key: '  ',
        host: ''
      )

      expect(config.missing_fields).to include('public_key', 'secret_key')
      expect(config.missing_fields).not_to include('host')
    end
  end

  describe '#save' do
    it 'saves configuration to file' do
      config = described_class.new(
        public_key: 'save_public',
        secret_key: 'save_secret',
        host: 'https://save.langfuse.com'
      )

      expect(config.save).to be true
      expect(File.exist?(test_config_file)).to be true

      # Verify saved content
      saved_config = YAML.load_file(test_config_file)
      expect(saved_config['profiles']['default']['public_key']).to eq('save_public')
      expect(saved_config['profiles']['default']['secret_key']).to eq('save_secret')
    end

    it 'saves to specific profile' do
      config = described_class.new(
        public_key: 'prod_public',
        secret_key: 'prod_secret'
      )

      config.save('production')

      saved_config = YAML.load_file(test_config_file)
      expect(saved_config['profiles']['production']['public_key']).to eq('prod_public')
    end

    it 'sets restrictive file permissions' do
      config = described_class.new(
        public_key: 'test_public',
        secret_key: 'test_secret'
      )

      config.save

      file_mode = File.stat(test_config_file).mode & 0777
      expect(file_mode).to eq(0600)
    end

    it 'creates config directory if it does not exist' do
      FileUtils.rm_rf(test_config_dir)

      config = described_class.new(
        public_key: 'test_public',
        secret_key: 'test_secret'
      )

      config.save

      expect(Dir.exist?(test_config_dir)).to be true
      expect(File.exist?(test_config_file)).to be true
    end
  end

  describe '#to_h' do
    it 'returns configuration as hash' do
      config = described_class.new(
        public_key: 'test_public',
        secret_key: 'test_secret',
        host: 'https://test.langfuse.com'
      )

      hash = config.to_h

      expect(hash[:public_key]).to eq('test_public')
      expect(hash[:secret_key]).to eq('test_secret')
      expect(hash[:host]).to eq('https://test.langfuse.com')
      expect(hash[:profile]).to eq('default')
      expect(hash[:output_format]).to eq('json')
      expect(hash[:page_limit]).to eq(50)
    end
  end

  describe '.load' do
    before do
      config_data = {
        'profiles' => {
          'test' => {
            'public_key' => 'test_public',
            'secret_key' => 'test_secret'
          }
        }
      }
      File.write(test_config_file, config_data.to_yaml)
    end

    it 'loads configuration for specified profile' do
      config = described_class.load('test')

      expect(config.public_key).to eq('test_public')
      expect(config.secret_key).to eq('test_secret')
    end
  end
end
