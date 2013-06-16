require 'bundler'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

Bundler::GemHelper.install_tasks

task :fetch_assets do
  system "/bin/rm -rf vendor/assets; mkdir -p vendor/assets; cd vendor/assets; curl -L https://github.com/cloudinary/cloudinary_js/tarball/master | tar zxvf - --strip=1"
  system "mkdir -p vendor/assets/javascripts; mv vendor/assets/js vendor/assets/javascripts/cloudinary"
  File.open("vendor/assets/javascripts/cloudinary/index.js", "w") do 
    |f|
    f.puts "//= require ./jquery.ui.widget.js"
    f.puts "//= require ./jquery.iframe-transport.js"
    f.puts "//= require ./jquery.fileupload.js"
    f.puts "//= require ./jquery.cloudinary.js"
  end
  File.open("vendor/assets/javascripts/cloudinary/processing.js", "w") do 
    |f|
    f.puts "//= require ./canvas-to-blob.min.js"
    f.puts "//= require ./load-image.min.js"
    f.puts "//= require ./jquery.fileupload-process.js"
    f.puts "//= require ./jquery.fileupload-image.js"
    f.puts "//= require ./jquery.fileupload-validate.js"
  end
end

task :build=>:fetch_assets
