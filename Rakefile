require 'bundler'
Bundler::GemHelper.install_tasks

task :fetch_assets do
  system "/bin/rm -rf assets; mkdir -p assets; cd assets; curl -L https://github.com/cloudinary/cloudinary_js/tarball/master | tar zxvf - --strip=1"
end

task :build=>:fetch_assets
