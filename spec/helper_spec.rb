require 'spec_helper'

describe Helpers::IntegrationTestCaseHelper do
  before(:all) do
    @cld_test_addons = ENV["CLD_TEST_ADDONS"]
  end

  after(:all) do
    ENV["CLD_TEST_ADDONS"] = @cld_test_addons
  end

  it "should test add on" do
    ENV["CLD_TEST_ADDONS"] = nil

    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_WEBPURIFY)).to eq(false)

    ENV["CLD_TEST_ADDONS"] = "all"

    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_WEBPURIFY)).to eq(true)
    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_JPEGMINI)).to eq(true)

    ENV["CLD_TEST_ADDONS"] = "webpurify"

    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_WEBPURIFY)).to eq(true)

    ENV["CLD_TEST_ADDONS"] = "webpurify,aspose"

    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_WEBPURIFY)).to eq(true)
    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_ASPOSE)).to eq(true)
    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_AZURE)).to eq(false)

    ENV["CLD_TEST_ADDONS"] = "WeBPuRiFY,aSPoSe"

    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_WEBPURIFY)).to eq(true)
    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_ASPOSE)).to eq(true)
    expect(Helpers::IntegrationTestCaseHelper.should_test_addon(Helpers::AddonType::ADDON_AZURE)).to eq(false)
  end
end
