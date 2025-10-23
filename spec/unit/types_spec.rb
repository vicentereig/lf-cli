require 'spec_helper'
require 'langfuse/cli/types'

RSpec.describe Langfuse::CLI::Types do
  describe 'MetricsView' do
    it 'accepts valid view types' do
      expect { described_class::MetricsView.deserialize('traces') }.not_to raise_error
      expect { described_class::MetricsView.deserialize('observations') }.not_to raise_error
      expect { described_class::MetricsView.deserialize('scores-numeric') }.not_to raise_error
      expect { described_class::MetricsView.deserialize('scores-categorical') }.not_to raise_error
    end

    it 'rejects invalid view types' do
      expect { described_class::MetricsView.deserialize('invalid') }.to raise_error(KeyError)
    end

    it 'can serialize back to string' do
      view = described_class::MetricsView::Traces
      expect(view.serialize).to eq('traces')
    end
  end

  describe 'Measure' do
    it 'accepts valid measure types' do
      expect { described_class::Measure.deserialize('count') }.not_to raise_error
      expect { described_class::Measure.deserialize('latency') }.not_to raise_error
      expect { described_class::Measure.deserialize('tokens') }.not_to raise_error
    end

    it 'rejects invalid measure types' do
      expect { described_class::Measure.deserialize('invalid') }.to raise_error(KeyError)
    end
  end

  describe 'Aggregation' do
    it 'accepts valid aggregation types' do
      expect { described_class::Aggregation.deserialize('count') }.not_to raise_error
      expect { described_class::Aggregation.deserialize('avg') }.not_to raise_error
      expect { described_class::Aggregation.deserialize('p95') }.not_to raise_error
    end

    it 'rejects invalid aggregation types' do
      expect { described_class::Aggregation.deserialize('invalid') }.to raise_error(KeyError)
    end
  end

  describe 'ObservationType' do
    it 'accepts valid observation types' do
      expect { described_class::ObservationType.deserialize('generation') }.not_to raise_error
      expect { described_class::ObservationType.deserialize('span') }.not_to raise_error
      expect { described_class::ObservationType.deserialize('event') }.not_to raise_error
    end

    it 'rejects invalid observation types' do
      expect { described_class::ObservationType.deserialize('invalid') }.to raise_error(KeyError)
    end
  end

  describe 'MetricsQuery' do
    it 'creates a valid query struct' do
      query = described_class::MetricsQuery.new(
        view: 'traces',
        measure: 'count',
        aggregation: 'count'
      )

      expect(query.view).to eq('traces')
      expect(query.measure).to eq('count')
      expect(query.aggregation).to eq('count')
    end

    it 'converts to hash correctly' do
      query = described_class::MetricsQuery.new(
        view: 'traces',
        measure: 'count',
        aggregation: 'sum',
        dimensions: ['name', 'userId'],
        limit: 50
      )

      hash = query.to_h

      expect(hash['view']).to eq('traces')
      expect(hash['metrics']).to eq([{ 'measure' => 'count', 'aggregation' => 'sum' }])
      expect(hash['dimensions']).to eq([{ 'field' => 'name' }, { 'field' => 'userId' }])
      expect(hash['limit']).to eq(50)
    end

    it 'omits nil values from hash' do
      query = described_class::MetricsQuery.new(
        view: 'traces',
        measure: 'count',
        aggregation: 'count'
      )

      hash = query.to_h

      expect(hash).not_to have_key('dimensions')
      expect(hash).not_to have_key('fromTimestamp')
      expect(hash).not_to have_key('toTimestamp')
    end
  end
end
