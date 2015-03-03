require 'rspec'
require 'spec_helper'
require 'cloudinary'
require 'action_view'
require 'cloudinary/helper'
require 'action_view/test_case'

describe 'video helper' do

  let(:helper)  {(Class.new { include CloudinaryHelper}).new}


  context 'vl_video_tag' do
    subject(:tag) { TagHelper.new helper.cl_video_tag(sources, options) }

    context 'basic options' do
      let(:options) {{:cloud_name => "amir", :html_height => "100px", :html_width => "200px"}}
      let(:sources) { "movie.mp4"}
      it "should create a basic tag" do
        expect(tag.name).to eq("video")
      end
      describe "attributes" do
        subject {tag.attributes}
        it { is_expected.to include "height" => "100px"}
        it { is_expected.to include "width" => "200px"}
        it { is_expected.to include "src" => "http://res.cloudinary.com/amir/image/upload/movie.mp4"}
      end
      
      
    end
    
    context 'multiple sources' do

      let(:options) {{:cloud_name => "amir", :html_height => "100px"}}
      let(:sources) {["movie.mp4", "movie.webm"]}
      it "should create a tag with multiple resources" do
        expect(tag.children.length).to eq(2)
      end
      it "should have \"source\" children" do
        expect(tag.children[0].name).to eq("source")
        expect(tag.children[1].name).to eq("source")
      end
      it "should have one child with mp4 source" do
        expect( tag.children.count {|c| /\.mp4$/ =~ c['src']}).to eq(1)
      end
      it "should have one child with webm source" do
        expect( tag.children.count {|c| /\.webm$/ =~ c['src']}).to eq(1)
      end
    end
    context 'transformations' do
      let(:options) {{:cloud_name => "amir", 
                      :html_height => "100px", 
                      :html_width => "200px",
                      :video_codec => {
                        :codec => 'h264'
                      },
                      :audio_codec => 'acc',
                      :start_offset => 3
      }}
      let(:sources) { "movie.mp4"}
      it "should create a tag with tranformation" do
        expect(tag["src"]).to match /ac_acc/
        expect(tag["src"]).to match /vc_h264/
        expect(tag["src"]).to match /so_3/

      end
    end
  end
end
