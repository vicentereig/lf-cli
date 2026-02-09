require 'faraday'
require 'faraday/retry'
require 'json'

module Langfuse
  module CLI
    class Client
      class APIError < StandardError; end
      class AuthenticationError < APIError; end
      class NotFoundError < APIError; end
      class RateLimitError < APIError; end
      class TimeoutError < APIError; end

      attr_reader :host, :public_key

      def initialize(config)
        @host = config.host
        @public_key = config.public_key
        @secret_key = config.secret_key
        @connection = build_connection
      end

      # Simple connection test without retries
      def test_connection
        test_conn = Faraday.new(url: @host) do |conn|
          conn.options.timeout = 5
          conn.options.open_timeout = 5
          conn.request :authorization, :basic, @public_key, @secret_key
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end

        response = test_conn.get('/api/public/traces', { limit: 1 })
        handle_response(response)
      rescue Faraday::TimeoutError
        raise TimeoutError, "Connection timed out. Please check your host URL and network connection."
      rescue Faraday::ConnectionFailed => e
        raise APIError, "Connection failed: #{e.message}"
      end

      # Traces API
      def list_traces(filters = {})
        params = build_trace_params(filters)
        paginate('/api/public/traces', params)
      end

      def get_trace(trace_id)
        request(:get, "/api/public/traces/#{trace_id}")
      end

      # Sessions API
      def list_sessions(filters = {})
        params = build_session_params(filters)
        paginate('/api/public/sessions', params)
      end

      def get_session(session_id)
        request(:get, "/api/public/sessions/#{session_id}")
      end

      # Observations API
      def list_observations(filters = {})
        params = build_observation_params(filters)
        paginate('/api/public/observations', params)
      end

      def get_observation(observation_id)
        request(:get, "/api/public/observations/#{observation_id}")
      end

      # Metrics API
      def query_metrics(query_params)
        request(:post, '/api/public/metrics', query_params)
      end

      # Scores API
      def list_scores(filters = {})
        params = build_score_params(filters)
        paginate('/api/public/scores', params)
      end

      def get_score(score_id)
        request(:get, "/api/public/scores/#{score_id}")
      end

      private

      def build_connection
        Faraday.new(url: @host) do |conn|
          conn.options.timeout = 30      # 30 seconds read timeout
          conn.options.open_timeout = 10 # 10 seconds connection timeout

          conn.request :authorization, :basic, @public_key, @secret_key
          conn.request :json
          conn.request :retry, {
            max: 3,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2,
            retry_statuses: [429, 500, 502, 503, 504],
            methods: [:get, :post]
          }
          conn.response :json, content_type: /\bjson$/

          # Enable debug logging if DEBUG=1
          if ENV['DEBUG'] == '1'
            conn.response :logger, nil, { headers: true, bodies: true }
          end

          conn.adapter Faraday.default_adapter
        end
      end

      def request(method, path, params = {})
        response = case method
                   when :get
                     @connection.get(path, params)
                   when :post
                     @connection.post(path, params)
                   when :put
                     @connection.put(path, params)
                   when :delete
                     @connection.delete(path, params)
                   else
                     raise ArgumentError, "Unsupported HTTP method: #{method}"
                   end

        handle_response(response)
      rescue Faraday::TimeoutError => e
        raise TimeoutError, "Request timed out. Please check your network connection and host URL."
      rescue Faraday::ConnectionFailed => e
        raise APIError, "Connection failed: #{e.message}"
      end

      def paginate(path, params = {})
        page = params[:page] || 1
        limit = params[:limit] || 50
        requested_limit = limit  # Remember the original limit to stop pagination
        all_results = []

        loop do
          response = request(:get, path, params.merge(page: page, limit: limit))

          # Handle both array and hash responses
          data = response.is_a?(Hash) && response['data'] ? response['data'] : response
          break if data.nil? || (data.is_a?(Array) && data.empty?)

          all_results.concat(Array(data))

          # Stop if we've collected enough results
          break if all_results.length >= requested_limit

          # Check if there are more pages
          meta = response.is_a?(Hash) ? response['meta'] : nil
          break unless meta && meta['totalPages'] && page < meta['totalPages']

          page += 1
        end

        # Return only the requested number of results
        all_results.take(requested_limit)
      end

      def handle_response(response)
        case response.status
        when 200..299
          response.body
        when 401
          raise AuthenticationError, "Authentication failed. Check your API keys."
        when 404
          raise NotFoundError, "Resource not found: #{response.body}"
        when 429
          raise RateLimitError, "Rate limit exceeded. Please try again later."
        when 400..499
          error_message = extract_error_message(response.body)
          raise APIError, "Client error (#{response.status}): #{error_message}"
        when 500..599
          error_message = extract_error_message(response.body)
          raise APIError, "Server error (#{response.status}): #{error_message}"
        else
          raise APIError, "Unexpected response status: #{response.status}"
        end
      end

      def extract_error_message(body)
        return body unless body.is_a?(Hash)
        body['message'] || body['error'] || body.to_s
      end

      # Parameter builders
      def build_trace_params(filters)
        params = {}
        params[:userId] = filters[:user_id] if filters[:user_id]
        params[:name] = filters[:name] if filters[:name]
        params[:sessionId] = filters[:session_id] if filters[:session_id]
        params[:tags] = filters[:tags] if filters[:tags]
        params[:fromTimestamp] = parse_timestamp(filters[:from]) if filters[:from]
        params[:toTimestamp] = parse_timestamp(filters[:to]) if filters[:to]
        params[:page] = filters[:page] if filters[:page]
        params[:limit] = filters[:limit] if filters[:limit]
        params
      end

      def build_session_params(filters)
        params = {}
        params[:fromTimestamp] = parse_timestamp(filters[:from]) if filters[:from]
        params[:toTimestamp] = parse_timestamp(filters[:to]) if filters[:to]
        params[:page] = filters[:page] if filters[:page]
        params[:limit] = filters[:limit] if filters[:limit]
        params
      end

      def build_observation_params(filters)
        params = {}
        params[:name] = filters[:name] if filters[:name]
        params[:userId] = filters[:user_id] if filters[:user_id]
        params[:traceId] = filters[:trace_id] if filters[:trace_id]
        params[:type] = filters[:type] if filters[:type]
        params[:fromTimestamp] = parse_timestamp(filters[:from]) if filters[:from]
        params[:toTimestamp] = parse_timestamp(filters[:to]) if filters[:to]
        params[:page] = filters[:page] if filters[:page]
        params[:limit] = filters[:limit] if filters[:limit]
        params
      end

      def build_score_params(filters)
        params = {}
        params[:name] = filters[:name] if filters[:name]
        params[:fromTimestamp] = parse_timestamp(filters[:from]) if filters[:from]
        params[:toTimestamp] = parse_timestamp(filters[:to]) if filters[:to]
        params[:page] = filters[:page] if filters[:page]
        params[:limit] = filters[:limit] if filters[:limit]
        params
      end

      def parse_timestamp(timestamp)
        return timestamp if timestamp.is_a?(String) && timestamp.match?(/^\d{4}-\d{2}-\d{2}T/)

        # Try to parse with chronic if available
        begin
          require 'chronic'
          parsed = Chronic.parse(timestamp)
          parsed&.iso8601
        rescue LoadError
          timestamp
        end
      end
    end
  end
end
