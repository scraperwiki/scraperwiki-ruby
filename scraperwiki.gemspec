Gem::Specification.new do |s|
  s.name        = 'scraperwiki'
  s.version     = '2.0.2'
  s.date        = '2013-04-04'
  s.summary     = "ScraperWiki"
  s.description = "A library for scraping web pages and saving data easily"
  s.authors     = ["Francis irving"]
  s.email       = 'francis@scraperwiki.com'
  s.files       = ["lib/scraperwiki.rb", "lib/scraperwiki/sqlite_save_info.rb"]
  s.homepage    = 'http://rubygems.org/gems/scraperwiki'

  s.add_dependency "httpclient"
  s.add_dependency "sqlite3"
end
