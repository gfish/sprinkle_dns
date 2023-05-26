$:.push File.expand_path("../lib", __FILE__)

require 'sprinkle_dns/version'

Gem::Specification.new do |gem|
  gem.name        = "sprinkle_dns"
  gem.version     = SprinkleDNS::VERSION
  gem.authors     = ["Kasper Grubbe"]
  gem.email       = ["kaspergrubbe@gmail.com"]
  gem.homepage    = "http://github.com/gfish/sprinkle_dns"
  gem.summary     = %q{Make handling DNS easier}
  gem.description = %q{Make handling DNS easier by using simple Ruby constructs}

  gem.licenses = ['MIT', 'GPL-2.0']

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.4.0"
  gem.add_runtime_dependency 'aws-sdk-route53', '~> 1.21'

  gem.add_development_dependency "rspec", '~> 3.8'
  gem.add_development_dependency "simplecov", '~> 0.16'
  gem.add_development_dependency "pry", '~> 0.14.2'
  gem.add_development_dependency "rake", '~> 12.3'
  gem.add_development_dependency "vcr", '~> 3.0'
  gem.add_development_dependency "webmock", '~> 2.3'
  gem.add_development_dependency "rexml", '~> 3.2'
end
