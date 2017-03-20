$:.push File.expand_path("../lib", __FILE__)

require 'sprinkle_dns/version'

Gem::Specification.new do |gem|
  gem.name        = "sprinkle_dns"
  gem.version     = SprinkleDNS::VERSION
  gem.authors     = ["Kasper Grubbe"]
  gem.email       = ["kaspergrubbe@gmail.com"]
  gem.homepage    = "http://github.com/gfish/sprinkle_dns"
  gem.summary     = %q{Make handling DNS easier}
  gem.description = %q{Make handling DNS easier}

  gem.licenses = ['MIT', 'GPL-2']

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'aws-sdk', '~> 2.1.36'

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "vcr", '~> 3.0'
  gem.add_development_dependency "webmock", '~> 2.3'
end
