require 'thor'
require 'tty-prompt'

module Langfuse
  module CLI
    module Commands
      class ConfigCommand < Thor
        namespace :config

        def self.exit_on_failure?
          true
        end

        desc 'setup', 'Interactive configuration setup (supports env vars for non-interactive mode)'
        long_desc <<-LONGDESC
          Set up Langfuse CLI configuration interactively or via environment variables.

          Environment variables (for non-interactive mode):
            LANGFUSE_PROJECT_NAME - Your Langfuse project name
            LANGFUSE_PUBLIC_KEY   - Your Langfuse public key
            LANGFUSE_SECRET_KEY   - Your Langfuse secret key
            LANGFUSE_HOST         - Langfuse host URL (default: https://cloud.langfuse.com)
            LANGFUSE_PROFILE      - Profile name to save as (default: default)

          Examples:
            # Interactive mode
            $ lf config setup

            # Non-interactive mode via environment variables
            $ LANGFUSE_PROJECT_NAME=my-project \\
              LANGFUSE_PUBLIC_KEY=pk-lf-xxx \\
              LANGFUSE_SECRET_KEY=sk-lf-xxx \\
              LANGFUSE_PROFILE=my-profile \\
              lf config setup
        LONGDESC
        def setup
          prompt = TTY::Prompt.new

          # Check for environment variables for non-interactive mode
          project_name = ENV['LANGFUSE_PROJECT_NAME']
          public_key = ENV['LANGFUSE_PUBLIC_KEY']
          secret_key = ENV['LANGFUSE_SECRET_KEY']
          host = ENV['LANGFUSE_HOST'] || 'https://cloud.langfuse.com'
          profile_name = ENV['LANGFUSE_PROFILE'] || 'default'

          # Determine if we're in non-interactive mode
          non_interactive = !public_key.nil? && !secret_key.nil?

          if non_interactive
            puts "🔑 Running in non-interactive mode (using environment variables)\n\n"
          else
            puts "\n🔑 Langfuse CLI Configuration Setup\n\n"
          end

          # Prompt for missing values in interactive mode
          unless non_interactive
            project_name ||= prompt.ask('Enter your Langfuse project name:', required: false)

            # Show URL hint if project name was provided
            if project_name && !project_name.empty?
              settings_url = "#{host}/project/#{project_name}/settings"
              prompt.say("💡 Visit: #{settings_url}")
              prompt.say("   (to get your API keys)\n")
            end

            public_key = prompt.ask('Enter your Langfuse public key:', required: true)
            secret_key = prompt.mask('Enter your Langfuse secret key:', required: true)
            host = prompt.ask('Enter host:', default: 'https://cloud.langfuse.com')
            profile_name = prompt.ask('Save as profile name:', default: 'default')
          end

          # Test connection
          begin
            config = Config.new(
              public_key: public_key,
              secret_key: secret_key,
              host: host
            )

            client = Client.new(config)
            print "Testing connection... "
            client.test_connection
            prompt.ok('Success!')

            # Save configuration
            config.save(profile_name)
            prompt.ok("Configuration saved to ~/.langfuse/config.yml")
            puts "\nYou're all set! Try: langfuse traces list"
          rescue Client::TimeoutError => e
            prompt.error("Connection test failed: #{e.message}")
            prompt.error("The host '#{host}' may be incorrect or unreachable.")
            raise_cli_error("Connection test failed: #{e.message}")
          rescue Client::AuthenticationError => e
            prompt.error("Connection test failed: #{e.message}")
            prompt.error("Please check your credentials and try again.")
            raise_cli_error("Connection test failed: #{e.message}")
          rescue Client::APIError => e
            prompt.error("Connection test failed: #{e.message}")
            raise_cli_error("Connection test failed: #{e.message}")
          end
        end

        desc 'set PROFILE', 'Set configuration for a profile'
        option :public_key, type: :string, required: true, desc: 'Langfuse public key'
        option :secret_key, type: :string, required: true, desc: 'Langfuse secret key'
        option :host, type: :string, default: 'https://cloud.langfuse.com', desc: 'Langfuse host URL'
        def set(profile)
          prompt = TTY::Prompt.new

          config = Config.new(
            public_key: options[:public_key],
            secret_key: options[:secret_key],
            host: options[:host]
          )

          config.save(profile)
          prompt.ok("Configuration saved for profile: #{profile}")
        end

        desc 'show [PROFILE]', 'Show configuration for a profile'
        def show(profile = 'default')
          config = Config.new(profile: profile)

          puts "\nConfiguration for profile: #{profile}"
          puts "─" * 50
          puts "Host:         #{config.host}"
          puts "Public Key:   #{mask_key(config.public_key)}"
          puts "Secret Key:   #{mask_key(config.secret_key)}"
          puts "Output Format: #{config.output_format}"
          puts "Page Limit:   #{config.page_limit}"
          puts "─" * 50
        end

        desc 'list', 'List all configuration profiles'
        def list
          config_file = File.expand_path('~/.langfuse/config.yml')

          unless File.exist?(config_file)
            puts "No configuration file found at #{config_file}"
            puts "Run 'langfuse config setup' to create one."
            return
          end

          require 'yaml'
          config_data = YAML.load_file(config_file)
          profiles = config_data['profiles'] || {}

          if profiles.empty?
            puts "No profiles configured."
            puts "Run 'langfuse config setup' to create one."
            return
          end

          puts "\nConfigured Profiles:"
          puts "─" * 50

          profiles.each do |name, profile_config|
            puts "\n#{name}:"
            puts "  Host:       #{profile_config['host']}"
            puts "  Public Key: #{mask_key(profile_config['public_key'])}"
          end

          puts "\n─" * 50
        end

        private

        def mask_key(key)
          return '' if key.nil? || key.empty?
          return key if key.length < 8

          "#{key[0..7]}#{'*' * (key.length - 8)}"
        end

        def raise_cli_error(message)
          raise Langfuse::CLI::Error, message
        end
      end
    end
  end
end
