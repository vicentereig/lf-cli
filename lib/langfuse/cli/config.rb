require 'yaml'
require 'fileutils'

module Langfuse
  module CLI
    class Config
      attr_accessor :public_key, :secret_key, :host, :profile, :output_format, :page_limit

      DEFAULT_HOST = 'https://cloud.langfuse.com'
      DEFAULT_OUTPUT_FORMAT = 'table'
      DEFAULT_PAGE_LIMIT = 50
      CONFIG_DIR = File.expand_path('~/.langfuse')
      CONFIG_FILE = File.join(CONFIG_DIR, 'config.yml')

      def initialize(options = {})
        @profile = options[:profile] || ENV['LANGFUSE_PROFILE'] || 'default'
        load_config
        merge_options(options)
      end

      # Load configuration from file and environment variables
      # Priority: passed options > ENV vars > config file > defaults
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
      def load_from_file
        config_data = YAML.load_file(CONFIG_FILE)

        # Load profile-specific config
        profile_config = config_data.dig('profiles', @profile) || config_data['default'] || {}

        @public_key = profile_config['public_key'] if profile_config['public_key']
        @secret_key = profile_config['secret_key'] if profile_config['secret_key']
        @host = profile_config['host'] if profile_config['host']
        @output_format = profile_config['output_format'] if profile_config['output_format']
        @page_limit = profile_config['page_limit'] if profile_config['page_limit']
      rescue => e
        warn "Warning: Error loading config file: #{e.message}"
      end

      # Load configuration from environment variables
      def load_from_env
        @public_key = ENV['LANGFUSE_PUBLIC_KEY'] if ENV['LANGFUSE_PUBLIC_KEY']
        @secret_key = ENV['LANGFUSE_SECRET_KEY'] if ENV['LANGFUSE_SECRET_KEY']
        @host = ENV['LANGFUSE_HOST'] if ENV['LANGFUSE_HOST']
      end

      # Merge passed options (highest priority)
      def merge_options(options)
        @public_key = options[:public_key] if options[:public_key]
        @secret_key = options[:secret_key] if options[:secret_key]
        @host = options[:host] if options[:host]
        @output_format = options[:format] if options[:format]
        @page_limit = options[:limit] if options[:limit]
      end

      # Validate that required configuration is present
      def valid?
        !@public_key.nil? && !@secret_key.nil? && !@host.nil?
      end

      # Get list of missing required fields
      def missing_fields
        fields = []
        fields << 'public_key' if @public_key.nil?
        fields << 'secret_key' if @secret_key.nil?
        fields << 'host' if @host.nil?
        fields
      end

      # Save current configuration to file
      def save(profile_name = nil)
        profile_name ||= @profile

        # Ensure config directory exists
        FileUtils.mkdir_p(CONFIG_DIR)

        # Load existing config or create new
        config_data = File.exist?(CONFIG_FILE) ? YAML.load_file(CONFIG_FILE) : {}
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
      def self.load(profile = nil)
        new(profile: profile)
      end

      # Get configuration as a hash
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
    end
  end
end
