require "bundler/setup"
require "langfuse_cli"
require "vcr"
require "webmock/rspec"
require "byebug"

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Filter out VCR-tagged tests unless explicitly running with cassettes
  config.filter_run_when_matching :focus
end

# Configure VCR for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Allow real HTTP connections when VCR is turned off
  config.allow_http_connections_when_no_cassette = false

  # Filter sensitive data from cassettes
  config.filter_sensitive_data('<LANGFUSE_PUBLIC_KEY>') do |interaction|
    interaction.request.headers['Authorization']&.first&.split(' ')&.last&.split(':')&.first
  end

  config.filter_sensitive_data('<LANGFUSE_SECRET_KEY>') do |interaction|
    auth = interaction.request.headers['Authorization']&.first
    if auth
      decoded = Base64.decode64(auth.split(' ').last)
      decoded.split(':').last
    end
  end

  # Filter API keys from request URIs
  config.filter_sensitive_data('<LANGFUSE_HOST>') do
    ENV['LANGFUSE_HOST'] || 'https://cloud.langfuse.com'
  end

  # Default cassette options
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, :body]
  }
end

# Helper method to load test configuration
def test_config
  {
    public_key: ENV['LANGFUSE_PUBLIC_KEY'] || 'test_public_key',
    secret_key: ENV['LANGFUSE_SECRET_KEY'] || 'test_secret_key',
    host: ENV['LANGFUSE_HOST'] || 'https://cloud.langfuse.com'
  }
end
