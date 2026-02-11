require 'sorbet-runtime'

module Langfuse
  module CLI
    module Types
      # Enum for metrics view types
      class MetricsView < T::Enum
        enums do
          Traces = new('traces')
          Observations = new('observations')
          ScoresNumeric = new('scores-numeric')
          ScoresCategorical = new('scores-categorical')
        end
      end

      # Enum for measure types
      class Measure < T::Enum
        enums do
          Count = new('count')
          Latency = new('latency')
          Value = new('value')
          Tokens = new('tokens')
          Cost = new('cost')
        end
      end

      # Enum for aggregation functions
      class Aggregation < T::Enum
        enums do
          Count = new('count')
          Sum = new('sum')
          Avg = new('avg')
          P50 = new('p50')
          P95 = new('p95')
          P99 = new('p99')
          Min = new('min')
          Max = new('max')
          Histogram = new('histogram')
        end
      end

      # Enum for time granularity
      class TimeGranularity < T::Enum
        enums do
          Minute = new('minute')
          Hour = new('hour')
          Day = new('day')
          Week = new('week')
          Month = new('month')
          Auto = new('auto')
        end
      end

      # Enum for observation types
      class ObservationType < T::Enum
        enums do
          Generation = new('generation')
          Span = new('span')
          Event = new('event')
        end
      end

      # Enum for output formats
      class OutputFormat < T::Enum
        enums do
          Table = new('table')
          JSON = new('json')
          CSV = new('csv')
        end
      end

      # Struct for metrics query parameters
      class MetricsQuery < T::Struct
        const :view, String
        const :measure, String
        const :aggregation, String
        prop :dimensions, T.nilable(T::Array[String]), default: nil
        prop :from_timestamp, T.nilable(String), default: nil
        prop :to_timestamp, T.nilable(String), default: nil
        prop :granularity, T.nilable(String), default: nil
        prop :limit, T.nilable(Integer), default: 100

        def to_h
          {
            'view' => view,
            'metrics' => [{ 'measure' => measure, 'aggregation' => aggregation }],
            'dimensions' => dimensions&.map { |d| { 'field' => d } },
            'fromTimestamp' => from_timestamp,
            'toTimestamp' => to_timestamp,
            'timeDimension' => granularity ? { 'granularity' => granularity } : nil,
            'limit' => limit
          }.compact
        end
      end
    end
  end
end
