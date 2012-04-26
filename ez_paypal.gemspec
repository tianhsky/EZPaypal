lib = File.expand_path("../lib/", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "date"
require "ez_paypal/version"

Gem::Specification.new do |s|

  # Basic info
  s.name        = "ez_paypal"
  s.version     = EZPaypal::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = Date.today.to_s
  s.summary     = "Paypal express checkout plugin"
  s.description = "Paypal express checkout plugin"
  s.authors     = ["Tianyu Huang"]
  s.email       = ["tianhsky@yahoo.com"]
  s.homepage    = "http://rubygems.org/gems/ez_paypal"

  # Dependencies
  #s.required_rubygems_version = ">= 1.8.22"
  s.add_dependency "ez_http", ">= 1.0.4"
  s.add_dependency "json", ">= 1.6.6"
  s.add_dependency "activesupport", ">= 3.2.2"

  # Files
  s.files       = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.extra_rdoc_files   = ["README.md", "doc/index.html"]

end
