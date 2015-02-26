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

  gem.add_runtime_dependency "fog"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rake"
end
