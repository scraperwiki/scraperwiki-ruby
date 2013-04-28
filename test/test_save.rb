require 'test/unit'
require 'scraperwiki'
require 'tmpdir'

def check_dump(expected_dump)
  actual_dump = `sqlite3 scraperwiki.sqlite .dump | egrep -v "PRAGMA foreign_keys|BEGIN TRANSACTION|COMMIT"`
  assert_equal actual_dump, expected_dump
end

class ScraperWikiSaveTest < Test::Unit::TestCase
  def test_english_hello
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 }, table_name = "animals")
      check_dump %Q{CREATE TABLE `animals` (`id` integer,`animal` text,`awesomeness` integer);
INSERT INTO "animals" VALUES(10,'fox',23);
CREATE UNIQUE INDEX `animals_index0` on `animals` (`id`);
}
    }
  end
end


