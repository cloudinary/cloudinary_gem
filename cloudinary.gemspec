# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cloudinary/version"

Gem::Specification.new do |s|
  s.name        = "cloudinary"
  s.version     = Cloudinary::VERSION
  s.authors     = ["Nadav Soferman","Itai Lahan","Tal Lev-Ami"]
  s.email       = ["nadav.soferman@cloudinary.com","itai.lahan@cloudinary.com","tal.levami@cloudinary.com"]
  s.homepage    = "http://cloudinary.com"
  s.license     = "MIT"

  s.summary     = %q{Client library for easily using the Cloudinary service}
  s.description = %q{Client library for easily using the Cloudinary service}

  s.rubyforge_project = "cloudinary"

  s.files         = (`git ls-files`.split("\n") - `git ls-files {test,spec,features,samples}/*`.split("\n")) + Dir.glob("vendor/assets/javascripts/*/*") + Dir.glob("vendor/assets/html/*")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "aws_cf_signer"
  s.add_dependency "rest-client"

  s.add_development_dependency "actionpack"
  s.add_development_dependency "nokogiri"

  if RUBY_VERSION >= "2.2.0"
    s.add_development_dependency "rake", ">= 13.0.1"
  else
    s.add_development_dependency "rake", "<= 12.2.1"
  end

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec", '>=3.5'
  s.add_development_dependency "rails", "~>5.2" if RUBY_VERSION >= "2.2.2"

  s.add_development_dependency "railties", "<= 4.2.7" if RUBY_VERSION <= "1.9.3"
  s.add_development_dependency "rspec-rails"

  s.add_development_dependency "rubyzip", "<=1.2.0" # support testing Ruby 1.9

  if RUBY_VERSION <= "2.4.0"
    s.add_development_dependency "simplecov", "<= 0.17.1" # support testing Ruby 1.9
  else
    s.add_development_dependency "simplecov", "> 0.18.0"
  end
end
