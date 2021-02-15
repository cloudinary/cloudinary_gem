module Helpers
  module IntegrationTestCaseHelper
    # Should a certain add on be tested?
    #
    # @param [String] add_on
    #
    # @return [Boolean]
    def self.should_test_addon(add_on)
      cld_test_addons = ENV.fetch("CLD_TEST_ADDONS", "").gsub(/\s+/, "").downcase

      if cld_test_addons == AddonType::ADDON_ALL
        return true
      end

      cld_test_addons.split(",").include?(add_on)
    end
  end
end
