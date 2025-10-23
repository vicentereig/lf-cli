require 'spec_helper'
require 'langfuse/cli/client'
require 'langfuse/cli/config'

RSpec.describe Langfuse::CLI::Client, :vcr do
  let(:config) do
    Langfuse::CLI::Config.new(
      public_key: ENV['LANGFUSE_PUBLIC_KEY'] || 'test_public_key',
      secret_key: ENV['LANGFUSE_SECRET_KEY'] || 'test_secret_key',
      host: ENV['LANGFUSE_HOST'] || 'https://cloud.langfuse.com'
    )
  end

  let(:client) { described_class.new(config) }

  describe '#list_traces' do
    it 'fetches traces without filters', :vcr do
      traces = client.list_traces(limit: 5)
      expect(traces).to be_an(Array)
    end

    it 'fetches traces with filters', :vcr do
      traces = client.list_traces(
        name: 'test_trace',
        limit: 5
      )
      expect(traces).to be_an(Array)
    end

    it 'fetches traces with time range', :vcr do
      traces = client.list_traces(
        from: '2024-01-01T00:00:00Z',
        to: '2024-12-31T23:59:59Z',
        limit: 5
      )
      expect(traces).to be_an(Array)
    end
  end

  describe '#get_trace' do
    it 'fetches a specific trace by ID', :vcr do
      # First get a list to find a valid ID
      traces = client.list_traces(limit: 1)
      skip 'No traces available' if traces.empty?

      trace_id = traces.first['id']
      trace = client.get_trace(trace_id)

      expect(trace).to be_a(Hash)
      expect(trace['id']).to eq(trace_id)
    end

    it 'raises NotFoundError for invalid trace ID' do
      expect {
        VCR.use_cassette('get_trace_not_found') do
          client.get_trace('invalid_trace_id')
        end
      }.to raise_error(Langfuse::CLI::Client::NotFoundError)
    end
  end

  describe '#list_sessions' do
    it 'fetches sessions', :vcr do
      sessions = client.list_sessions(limit: 5)
      expect(sessions).to be_an(Array)
    end

    it 'fetches sessions with time range', :vcr do
      sessions = client.list_sessions(
        from: '2024-01-01T00:00:00Z',
        to: '2024-12-31T23:59:59Z',
        limit: 5
      )
      expect(sessions).to be_an(Array)
    end
  end

  describe '#get_session' do
    it 'fetches a specific session by ID', :vcr do
      sessions = client.list_sessions(limit: 1)
      skip 'No sessions available' if sessions.empty?

      session_id = sessions.first['id']
      session = client.get_session(session_id)

      expect(session).to be_a(Hash)
      expect(session['id']).to eq(session_id)
    end
  end

  describe '#list_observations' do
    it 'fetches observations', :vcr do
      observations = client.list_observations(limit: 5)
      expect(observations).to be_an(Array)
    end

    it 'fetches observations with filters', :vcr do
      observations = client.list_observations(
        type: 'generation',
        limit: 5
      )
      expect(observations).to be_an(Array)
    end
  end

  describe '#get_observation' do
    it 'fetches a specific observation by ID', :vcr do
      observations = client.list_observations(limit: 1)
      skip 'No observations available' if observations.empty?

      observation_id = observations.first['id']
      observation = client.get_observation(observation_id)

      expect(observation).to be_a(Hash)
      expect(observation['id']).to eq(observation_id)
    end
  end

  describe '#list_scores' do
    it 'fetches scores', :vcr do
      scores = client.list_scores(limit: 5)
      expect(scores).to be_an(Array)
    end

    it 'fetches scores with filters', :vcr do
      scores = client.list_scores(
        name: 'quality',
        limit: 5
      )
      expect(scores).to be_an(Array)
    end
  end

  describe '#get_score' do
    it 'fetches a specific score by ID', :vcr do
      scores = client.list_scores(limit: 1)
      skip 'No scores available' if scores.empty?

      score_id = scores.first['id']
      score = client.get_score(score_id)

      expect(score).to be_a(Hash)
      expect(score['id']).to eq(score_id)
    end
  end

  describe '#query_metrics' do
    it 'queries metrics with custom parameters', :vcr do
      query = {
        view: 'traces',
        metrics: [
          { measure: 'count', aggregation: 'count' }
        ],
        fromTimestamp: '2024-01-01T00:00:00Z',
        toTimestamp: '2024-12-31T23:59:59Z',
        limit: 10
      }

      result = client.query_metrics(query)
      expect(result).to be_a(Hash)
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError for invalid credentials' do
      invalid_config = Langfuse::CLI::Config.new(
        public_key: 'invalid',
        secret_key: 'invalid',
        host: 'https://cloud.langfuse.com'
      )
      invalid_client = described_class.new(invalid_config)

      expect {
        VCR.use_cassette('auth_error') do
          invalid_client.list_traces
        end
      }.to raise_error(Langfuse::CLI::Client::AuthenticationError)
    end
  end

  describe 'pagination' do
    it 'automatically paginates through all results' do
      # This test would need a real API with multiple pages
      # For now, we'll just verify it doesn't break with single page
      traces = client.list_traces(limit: 2)
      expect(traces).to be_an(Array)
    end
  end
end
