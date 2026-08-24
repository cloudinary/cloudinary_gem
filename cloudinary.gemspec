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

  s.metadata = {
    "changelog_uri"     => "https://github.com/cloudinary/cloudinary_gem/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://cloudinary.com/documentation/rails_integration",
    "source_code_uri"   => "https://github.com/cloudinary/cloudinary_gem",
    "bug_tracker_uri"   => "https://github.com/cloudinary/cloudinary_gem/issues"
  }

  # docs/ and examples/ ship inside the gem so that agent-readable documentation is always
  # version-matched to the installed code. They are listed explicitly (rather than relying
  # on `git ls-files` alone) so that dropping them from the package is a deliberate change.
  s.files         = (`git ls-files`.split("\n").select { |f| !f.start_with?("test", "spec", "features", "samples") } +
    Dir.glob("docs/*.md") + Dir.glob("examples/*.rb") +
    Dir.glob("vendor/assets/javascripts/*/*") + Dir.glob("vendor/assets/html/*")).uniq
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 3', '< 5'

  s.add_dependency "faraday", ">= 2.0.1", "< 3.0.0"
  s.add_dependency "faraday-multipart", "~> 1.0", ">= 1.0.4"
  s.add_dependency "faraday-follow_redirects", "~> 0.5"
  s.add_dependency "ostruct"

  s.add_development_dependency "rails", ">= 6.1.7", "< 9.0.0"
  s.add_development_dependency "rexml", ">= 3.2.5", "< 4.0.0"
  s.add_development_dependency "actionpack", ">= 6.1.7", "< 9.0.0"
  s.add_development_dependency "nokogiri", ">= 1.12.5", "< 2.0.0"
  s.add_development_dependency "rake", ">= 13.0.6", "< 14.0.0"
  s.add_development_dependency "sqlite3", ">= 1.4.2", RUBY_VERSION >= "3.1" ? "< 3.0.0" : "< 2.0.0"
  s.add_development_dependency "rspec", ">= 3.11.2", "< 4.0.0"
  s.add_development_dependency "rspec-retry", ">= 0.6.2", "< 1.0.0"
  s.add_development_dependency "railties", ">= 6.0.4", "< 9.0.0"
  s.add_development_dependency "rspec-rails", ">= 6.0.4", "< 9.0.0"
  s.add_development_dependency "rubyzip", ">= 2.3.0", "< 3.0.0"
  s.add_development_dependency "simplecov", ">= 0.21.2", "< 1.0.0"
end
