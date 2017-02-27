module Helpers
  module TempFileHelpers
    def clean_up_temp_files!
      FileUtils.remove_entry temp_root
    end

    def temp_root
      @temp_root ||= Dir.mktmpdir 'test_root'
    end

    def copy_to_temp(source)
      source = File.join(RSpec.project_root, source) unless Pathname.new(source).directory?
      FileUtils.copy_entry source, temp_root
    end
  end
end
