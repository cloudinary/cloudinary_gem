require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Search do
  context 'unit' do
    it 'should create empty json' do
      query_hash = Cloudinary::Search.to_h
      expect(query_hash).to eq({})
    end

    it 'should always return same object in fluent interface' do
      instance = Cloudinary::Search.new
      %w(expression sort_by max_results next_cursor aggregate with_field).each do |method|
        same_instance = instance.send(method, 'emptyarg')
        expect(instance).to eq(same_instance)
      end
    end

    it 'should add expression to query' do
      query = Cloudinary::Search.expression('format:jpg').to_h
      expect(query).to eq(expression: 'format:jpg')
    end

    it 'should add sort_by to query' do
      query = Cloudinary::Search.sort_by('created_at', 'asc').sort_by('updated_at', 'desc').to_h
      expect(query).to eq(sort_by: [{ 'created_at' => 'asc' }, { 'updated_at' => 'desc' }])
    end

    it 'should add max_results to query' do
      query = Cloudinary::Search.max_results(10).to_h
      expect(query).to eq(max_results: 10)
    end

    it 'should add next_cursor to query' do
      query = Cloudinary::Search.next_cursor('ASDFIUHASF9832HAFSOF').to_h
      expect(query).to eq(next_cursor: 'ASDFIUHASF9832HAFSOF')
    end

    it 'should add aggregations arguments as array to query' do
      query = Cloudinary::Search.aggregate('format').aggregate('size_category').to_h
      expect(query).to eq(aggregate: %w(format size_category))
    end

    it 'should add with_field to query' do
      query = Cloudinary::Search.with_field('context').with_field('tags').to_h
      expect(query).to eq(with_field: %w(context tags))
    end

    it 'should add fields to query' do
      query = Cloudinary::Search.fields(%w[context tags]).fields('metadata').to_h
      expect(query).to eq(fields: %w(context tags metadata))
    end

    it "should not duplicate values" do
      expected = {
        [:url] => /.*\/resources\/search$/,
        [:payload] => {
          "aggregate" => %w[format resource_type],
          "fields" => %w[tags context metadata],
          "sort_by" => [
            { "created_at" => "desc" },
            { "public_id" => "asc" }
          ],
          "with_field" => %w[context tags]
        }
      }

      res = MockedSearchApi
        .sort_by("created_at", "asc")
        .sort_by("created_at")
        .sort_by("public_id", "asc")
        .aggregate("format")
        .aggregate("format")
        .aggregate("resource_type")
        .with_field("context")
        .with_field("context")
        .with_field("tags")
        .fields(%w[tags context])
        .fields('metadata')
        .fields('tags')
        .execute

      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  context 'unit Search URL' do
    include_context "config"
    before(:each) do
      ENV["CLOUDINARY_URL"] = "cloudinary://key:secret@test123?secure=true"
      Cloudinary.reset_config
    end

    let(:cloud_name) { Cloudinary.config.cloud_name }
    let(:root_path) { "https://res.cloudinary.com/#{cloud_name}" }
    let(:search_path) { "#{root_path}/search/" }

    search = Cloudinary::Search
               .expression("resource_type:image AND tags=kitten AND uploaded_at>1d AND bytes>1m")
               .sort_by("public_id", "desc")
               .max_results(30)

    b64query = "eyJleHByZXNzaW9uIjoicmVzb3VyY2VfdHlwZTppbWFnZSBBTkQgdGFncz1raXR0ZW4gQU5EIHVwbG9hZGVkX2F0" +
      "PjFkIEFORCBieXRlcz4xbSIsIm1heF9yZXN1bHRzIjozMCwic29ydF9ieSI6W3sicHVibGljX2lkIjoiZGVzYyJ9XX0="

    ttl300_sig  = "431454b74cefa342e2f03e2d589b2e901babb8db6e6b149abf25bc0dd7ab20b7"
    ttl1000_sig = "25b91426a37d4f633a9b34383c63889ff8952e7ffecef29a17d600eeb3db0db7"

    it 'should build Search URL using defaults' do
      expect(search.to_url).to eq("#{search_path}#{ttl300_sig}/300/#{b64query}")
    end

    it 'should build Search URL with next cursor' do
      expect(search.to_url(nil, NEXT_CURSOR)).to eq("#{search_path}#{ttl300_sig}/300/#{b64query}/#{NEXT_CURSOR}")
    end

    it 'should build Search URL with custom ttl and next cursor' do
      expect(search.to_url(1000, NEXT_CURSOR)).to eq("#{search_path}#{ttl1000_sig}/1000/#{b64query}/#{NEXT_CURSOR}")
    end

    it 'should build Search URL with custom ttl and next cursor from the class' do
      expect(search.ttl(1000).next_cursor(NEXT_CURSOR).to_url)
        .to eq("#{search_path}#{ttl1000_sig}/1000/#{b64query}/#{NEXT_CURSOR}")
    end

    it 'should build Search URL with private_cdn' do
      expect(search.to_url(300, "", { private_cdn: true }))
        .to eq("https://#{cloud_name}-res.cloudinary.com/search/#{ttl300_sig}/300/#{b64query}")
    end

    it 'should build Search URL with private_cdn from config' do
      Cloudinary.config do |config|
        config.private_cdn = true
      end
      expect(search.to_url(300, ""))
        .to eq("https://#{cloud_name}-res.cloudinary.com/search/#{ttl300_sig}/300/#{b64query}")
    end
  end

  context 'integration', :with_retries do
    SEARCH_TAG = TIMESTAMP_TAG + "_search"
    include_context 'cleanup', SEARCH_TAG
    prefix      = "api_test_#{SUFFIX}"
    test_id_1   = "#{prefix}_1"
    test_id_2   = "#{prefix}_2"
    test_id_3   = "#{prefix}_3"
    m_asset_ids = {}

    before(:all) do
      result                 = Cloudinary::Uploader.upload(TEST_IMG, public_id: test_id_1, tags: [TEST_TAG, TIMESTAMP_TAG, SEARCH_TAG], context: 'stage=in_review')
      m_asset_ids[test_id_1] = result["asset_id"]

      result                 = Cloudinary::Uploader.upload(TEST_IMG, public_id: test_id_2, tags: [TEST_TAG, TIMESTAMP_TAG, SEARCH_TAG], context: 'stage=new')
      m_asset_ids[test_id_2] = result["asset_id"]

      result                 = Cloudinary::Uploader.upload(TEST_IMG, public_id: test_id_3, tags: [TEST_TAG, TIMESTAMP_TAG, SEARCH_TAG], context: 'stage=validated')
      m_asset_ids[test_id_3] = result["asset_id"]

      sleep(1)
    end

    it "should return all images tagged with #{SEARCH_TAG}" do
      results = Cloudinary::Search.expression("tags:#{SEARCH_TAG}").execute
      expect(results['resources'].count).to eq 3
    end

    it "should return resource #{test_id_1}" do
      results = Cloudinary::Search.expression("public_id:#{test_id_1}").execute
      expect(results['resources'].count).to eq 1
    end

    it 'should paginate resources limited by tag and ordered by ascending public_id' do
      results = Cloudinary::Search.max_results(1).expression("tags:#{SEARCH_TAG}").sort_by('public_id', 'asc').execute
      expect(results['resources'].count).to eq 1
      expect(results['resources'][0]['public_id']).to eq test_id_1
      expect(results['total_count']).to eq 3

      results = Cloudinary::Search.max_results(1).expression("tags:#{SEARCH_TAG}").sort_by('public_id', 'asc').next_cursor(results['next_cursor']).execute
      expect(results['resources'].count).to eq 1
      expect(results['resources'][0]['public_id']).to eq test_id_2
      expect(results['total_count']).to eq 3

      results = Cloudinary::Search.max_results(1).expression("tags:#{SEARCH_TAG}").sort_by('public_id', 'asc').next_cursor(results['next_cursor']).execute
      expect(results['resources'].count).to eq 1
      expect(results['resources'][0]['public_id']).to eq test_id_3
      expect(results['total_count']).to eq 3
      expect(results['next_cursor']).to be_nil
    end

    it 'should include context' do
      results = Cloudinary::Search.expression("tags:#{SEARCH_TAG}").with_field('context').execute
      expect(results['resources'].count).to eq 3
      results['resources'].each do |res|
        expect(res['context'].keys).to eq ['stage']
      end
    end
    it 'should include context, tags and image_metadata' do
      results = Cloudinary::Search.expression("tags:#{SEARCH_TAG}").with_field('context').with_field('tags').with_field('image_metadata').execute
      expect(results['resources'].count).to eq 3
      results['resources'].each do |res|
        expect(res['context'].keys).to eq ['stage']
        expect(res.key?('image_metadata')).to eq true
        expect(res['tags'].count).to eq 3
      end
    end

    it 'returns resource by asset_id using colon' do
      results = Cloudinary::Search.expression("asset_id:#{m_asset_ids[test_id_1]}").execute
      expect(results['resources'].count).to eq 1
    end

    it 'returns resource by asset_id using equal sign' do
      results = Cloudinary::Search.expression("asset_id=#{m_asset_ids[test_id_1]}").execute
      expect(results['resources'].count).to eq 1
    end
  end
end
