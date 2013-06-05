# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ['Francis irving']
  gem.email         = 'francis@scraperwiki.com'
  gem.description   = 'A library for scraping web pages and saving data easily'
  gem.summary       = 'ScraperWiki'
  gem.homepage      = 'http://rubygems.org/gems/scraperwiki'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'scraperwiki'
  gem.require_paths = ['lib']
  gem.version       = '2.0.6'

  gem.add_dependency "httpclient"
  gem.add_dependency "sqlite3"
end
