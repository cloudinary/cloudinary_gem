# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cloudinary/version"

Gem::Specification.new do |s|
  s.name        = "cloudinary"
  s.version     = Cloudinary::VERSION
  s.authors     = ["Nadav Soferman","Itai Lahan","Tal Lev-Ami"]
  s.email       = ["nadav.soferman@cloudinary.com","itai.lahan@cloudinary.com","tal.levami@cloudinary.com"]
  s.homepage    = "https://cloudinary.com"
  s.license     = "MIT"

  s.summary     = %q{Client library for easily using the Cloudinary service}
  s.description = %q{Client library for easily using the Cloudinary service}

  s.files         = `git ls-files`.split("\n").select { |f| !f.start_with?("test", "spec", "features", "samples") } +
    Dir.glob("vendor/assets/javascripts/*/*") + Dir.glob("vendor/assets/html/*")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '~> 3'

  s.add_dependency "faraday", ">= 2.0.1", "< 3.0.0"
  s.add_dependency "faraday-multipart", "~> 1.0", ">= 1.0.4"
  s.add_dependency 'faraday-follow_redirects', '~> 0.3.0'

  s.add_development_dependency "rails", ">= 6.1.7", "< 8.0.0"
  s.add_development_dependency "rexml", ">= 3.2.5", "< 4.0.0"
  s.add_development_dependency "actionpack", ">= 6.1.7", "< 8.0.0"
  s.add_development_dependency "nokogiri", ">= 1.12.5", "< 2.0.0"
  s.add_development_dependency "rake", ">= 13.0.6", "< 14.0.0"
  s.add_development_dependency "sqlite3", ">= 1.4.2", "< 2.0.0"
  s.add_development_dependency "rspec", ">= 3.11.2", "< 4.0.0"
  s.add_development_dependency "rspec-retry", ">= 0.6.2", "< 1.0.0"
  s.add_development_dependency "railties", ">= 6.0.4", "< 8.0.0"
  s.add_development_dependency "rspec-rails", ">= 6.0.4", "< 7.0.0"
  s.add_development_dependency "rubyzip", ">= 2.3.0", "< 3.0.0"
  s.add_development_dependency "simplecov", ">= 0.21.2", "< 1.0.0"
end
