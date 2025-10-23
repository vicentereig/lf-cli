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

        desc 'setup', 'Interactive configuration setup'
        def setup
          prompt = TTY::Prompt.new

          puts "\n🔑 Langfuse CLI Configuration Setup\n\n"

          # Ask for project name
          project_name = prompt.ask('Enter your Langfuse project name:', required: true)

          # Open browser to settings page
          host = 'https://cloud.langfuse.com'
          settings_url = "#{host}/project/#{project_name}/settings"
          prompt.say("Opening browser to: #{settings_url}")
          prompt.say("(Or visit manually to get your API keys)\n")
          open_browser(settings_url)

          # Prompt for credentials
          public_key = prompt.ask('Enter your Langfuse public key:', required: true)
          secret_key = prompt.mask('Enter your Langfuse secret key:', required: true)
          host = prompt.ask('Enter host:', default: 'https://cloud.langfuse.com')
          profile_name = prompt.ask('Save as profile name:', default: 'default')

          # Test connection
          begin
            config = Config.new(
              public_key: public_key,
              secret_key: secret_key,
              host: host
            )

            client = Client.new(config)
            client.list_traces(limit: 1)
            prompt.ok('Testing connection... Success!')

            # Save configuration
            config.save(profile_name)
            prompt.ok("Configuration saved to ~/.langfuse/config.yml")
            puts "\nYou're all set! Try: langfuse traces list"
          rescue Client::AuthenticationError => e
            prompt.error("Connection test failed: #{e.message}")
            prompt.error("Please check your credentials and try again.")
            exit 1
          rescue Client::APIError => e
            prompt.error("Connection test failed: #{e.message}")
            exit 1
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

        def open_browser(url)
          case RbConfig::CONFIG['host_os']
          when /mswin|mingw|cygwin/
            system("start #{url}")
          when /darwin/
            system("open #{url}")
          when /linux|bsd/
            system("xdg-open #{url}")
          else
            # Fallback - just print the URL
            puts "Please open: #{url}"
          end
        end

        def mask_key(key)
          return '' if key.nil? || key.empty?
          return key if key.length < 8

          "#{key[0..7]}#{'*' * (key.length - 8)}"
        end
      end
    end
  end
end
