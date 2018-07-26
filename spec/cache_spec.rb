require 'spec_helper'
require 'cloudinary'
require 'rspec'

PUBLIC_ID = TEST_TAG + '_cache_' + SUFFIX

describe 'Responsive cache' do

  it 'should cache breakpoints' do

    true.should == false
  end
end