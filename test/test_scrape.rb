require 'test/unit'
require 'scraperwiki'

class ScraperWikiSaveTest < Test::Unit::TestCase

  def test_get_a_page
    content = ScraperWiki.scrape("http://xkcd.com/1/")
    assert_includes content, "Barrel - Part 1"
  end

end


