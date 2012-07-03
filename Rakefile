require 'bundler'
Bundler::GemHelper.install_tasks

task :fetch_assets do
  system "/bin/rm -rf vendor/assets; mkdir -p vendor/assets; cd vendor/assets; curl -L https://github.com/cloudinary/cloudinary_js/tarball/master | tar zxvf - --strip=1"
  system "mkdir -p vendor/assets/javascripts; mv vendor/assets/js vendor/assets/javascripts/cloudinary"
  File.open("vendor/assets/javascripts/cloudinary/index.js", "w"){|f| f.puts "//= require_tree ."}
end

task :build=>:fetch_assets
