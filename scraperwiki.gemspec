# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scraperwiki/version'
# require File.expand_path('../lib/scraperwiki/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Francis Irving']
  gem.email         = 'francis@scraperwiki.com'
  gem.description   = 'A library for scraping web pages and saving data easily'
  gem.summary       = 'ScraperWiki'
  gem.homepage      = 'http://rubygems.org/gems/scraperwiki'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'scraperwiki'
  gem.require_paths = ['lib']
  gem.version       = ScraperWiki::VERSION

  gem.add_dependency "httpclient"
  # gem.add_dependency "sqlite3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "debugger"
end
