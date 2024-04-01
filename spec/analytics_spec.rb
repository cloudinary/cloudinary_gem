# frozen_string_literal: true

require "spec_helper"

class AnalyticsTest
  ALGO_VERSION = 'B'
  include Cloudinary::Analytics
end

describe Cloudinary::Analytics do
  context 'encode version' do
    it 'returns "Alh" for input "1.24.0"' do
      expect(described_class.encode_version('1.24.0')).to eq('Alh')
    end

    it 'returns "AM" for input "12.0"' do
      expect(described_class.encode_version('12.0')).to eq('AM')
    end

    it 'returns "///" for input "43.21.26"' do
      expect(described_class.encode_version('43.21.26')).to eq('///')
    end

    it 'returns "AAA" for input "0.0.0"' do
      expect(described_class.encode_version('0.0.0')).to eq('AAA')
    end

    it 'raises RangeError for input "44.45.46"' do
      expect { described_class.encode_version('44.45.46') }.to raise_error(RangeError, 'Version must be smaller than 43.21.26')
    end
  end

  context 'get signature with integration' do
    it 'returns the expected signature' do
      test = AnalyticsTest.new

      test.product('B')
      test.sdk_code('B')
      test.sdk_version('2.0.0')
      test.tech_version('9.5')

      expect(test.sdk_analytics_signature).to eq('BBBAACH9')
    end
  end
end
