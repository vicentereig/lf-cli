require 'yaml'
require 'fileutils'
require 'sorbet-runtime'

module Langfuse
  module CLI
    class Config
      extend T::Sig

      attr_accessor :public_key, :secret_key, :host, :profile, :output_format, :page_limit

      DEFAULT_HOST = 'https://cloud.langfuse.com'
      DEFAULT_OUTPUT_FORMAT = 'table'
      DEFAULT_PAGE_LIMIT = 50
      CONFIG_DIR = File.expand_path('~/.langfuse')
      CONFIG_FILE = File.join(CONFIG_DIR, 'config.yml')

      sig { params(options: T::Hash[Symbol, T.untyped]).void }
      def initialize(options = {})
        @profile = normalize_string(options[:profile]) || normalize_string(ENV['LANGFUSE_PROFILE']) || 'default'
        load_config
        merge_options(options)
      end

      # Load configuration from file and environment variables
      # Priority: passed options > ENV vars > config file > defaults
      sig { void }
      def load_config
        # Start with defaults
        @host = DEFAULT_HOST
        @output_format = DEFAULT_OUTPUT_FORMAT
        @page_limit = DEFAULT_PAGE_LIMIT
        @public_key = nil
        @secret_key = nil

        # Load from config file if it exists
        if File.exist?(CONFIG_FILE)
          load_from_file
        end

        # Override with environment variables
        load_from_env
      end

      # Load configuration from YAML file
      sig { void }
      def load_from_file
        config_data = read_config_data

        # Load profile-specific config
        profiles = config_data['profiles'].is_a?(Hash) ? config_data['profiles'] : {}
        legacy_default = config_data['default'].is_a?(Hash) ? config_data['default'] : {}
        profile_config = profiles[@profile] || profiles['default'] || legacy_default

        @public_key = normalize_string(profile_config['public_key']) || @public_key
        @secret_key = normalize_string(profile_config['secret_key']) || @secret_key
        @host = normalize_string(profile_config['host']) || @host
        @output_format = normalize_string(profile_config['output_format']) || @output_format
        @page_limit = normalize_integer(profile_config['page_limit']) || @page_limit
      rescue => e
        warn "Warning: Error loading config file: #{e.message}"
      end

      # Load configuration from environment variables
      sig { void }
      def load_from_env
        @public_key = normalize_string(ENV['LANGFUSE_PUBLIC_KEY']) || @public_key
        @secret_key = normalize_string(ENV['LANGFUSE_SECRET_KEY']) || @secret_key
        @host = normalize_string(ENV['LANGFUSE_HOST']) || @host
      end

      # Merge passed options (highest priority)
      sig { params(options: T::Hash[Symbol, T.untyped]).void }
      def merge_options(options)
        @public_key = normalize_string(options[:public_key]) || @public_key
        @secret_key = normalize_string(options[:secret_key]) || @secret_key
        @host = normalize_string(options[:host]) || @host
        @output_format = normalize_string(options[:format]) || @output_format
        @page_limit = normalize_integer(options[:limit]) || @page_limit
      end

      # Validate that required configuration is present
      sig { returns(T::Boolean) }
      def valid?
        present?(@public_key) && present?(@secret_key) && present?(@host)
      end

      # Get list of missing required fields
      sig { returns(T::Array[String]) }
      def missing_fields
        fields = []
        fields << 'public_key' unless present?(@public_key)
        fields << 'secret_key' unless present?(@secret_key)
        fields << 'host' unless present?(@host)
        fields
      end

      # Save current configuration to file
      sig { params(profile_name: T.nilable(String)).returns(T::Boolean) }
      def save(profile_name = nil)
        profile_name ||= @profile

        # Ensure config directory exists
        FileUtils.mkdir_p(CONFIG_DIR)

        # Load existing config or create new
        config_data = File.exist?(CONFIG_FILE) ? read_config_data : {}
        config_data['profiles'] ||= {}

        # Update profile
        config_data['profiles'][profile_name] = {
          'public_key' => @public_key,
          'secret_key' => @secret_key,
          'host' => @host,
          'output_format' => @output_format,
          'page_limit' => @page_limit
        }

        # Write to file
        File.write(CONFIG_FILE, config_data.to_yaml)

        # Set restrictive permissions
        File.chmod(0600, CONFIG_FILE)

        true
      rescue => e
        warn "Error saving config: #{e.message}"
        false
      end

      # Load a specific profile
      sig { params(profile: T.nilable(String)).returns(Config) }
      def self.load(profile = nil)
        new(profile: profile)
      end

      # Get configuration as a hash
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def to_h
        {
          public_key: @public_key,
          secret_key: @secret_key,
          host: @host,
          profile: @profile,
          output_format: @output_format,
          page_limit: @page_limit
        }
      end

      private

      sig { params(value: T.untyped).returns(T.nilable(String)) }
      def normalize_string(value)
        return nil if value.nil?

        normalized = value.to_s.strip
        normalized.empty? ? nil : normalized
      end

      sig { params(value: T.untyped).returns(T.nilable(Integer)) }
      def normalize_integer(value)
        return nil if value.nil?

        Integer(value)
      rescue ArgumentError, TypeError
        nil
      end

      sig { params(value: T.nilable(String)).returns(T::Boolean) }
      def present?(value)
        !value.nil? && !value.strip.empty?
      end

      sig { returns(T::Hash[String, T.untyped]) }
      def read_config_data
        data = YAML.safe_load(
          File.read(CONFIG_FILE),
          permitted_classes: [],
          permitted_symbols: [],
          aliases: false
        )
        data.is_a?(Hash) ? data : {}
      rescue Errno::ENOENT
        {}
      end
    end
  end
end
