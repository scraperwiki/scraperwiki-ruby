require 'test/unit'
require 'scraperwiki'
require 'tmpdir'

def check_dump(expected_dump)
  actual_dump = `sqlite3 scraperwiki.sqlite .dump | egrep -v "PRAGMA foreign_keys|BEGIN TRANSACTION|COMMIT"`.strip
  expected_dump.strip!
  assert_equal actual_dump, expected_dump
end

class ScraperWikiSaveTest < Test::Unit::TestCase

  def test_save_two_animals_in_sequence
    # Make a temporary directory (erased at end of block)
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 }, table_name = "animals")
      ScraperWiki.save_sqlite(['id'], {'id'=> 20, 'animal'=> 'rabbit', 'awesomeness'=> 37 }, table_name = "animals")
      ScraperWiki.close_sqlite
      check_dump %Q{CREATE TABLE `animals` (`id` integer,`animal` text,`awesomeness` integer);
INSERT INTO "animals" VALUES(10,'fox',23);
INSERT INTO "animals" VALUES(20,'rabbit',37);
CREATE UNIQUE INDEX `animals_index0` on `animals` (`id`);}
    }
  end

  def test_save_two_animals_at_once_using_an_array
    Dir.mktmpdir { |dir|
      Dir.chdir dir

      datas = [
        {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 },
        {'id'=> 30, 'animal'=> 'polar bear', 'awesomeness'=> 99 }
      ]

      ScraperWiki.save_sqlite(['id'], datas, table_name = "animals")
      SQLiteMagic.close
      check_dump %Q{CREATE TABLE `animals` (`id` integer,`animal` text,`awesomeness` integer);
INSERT INTO "animals" VALUES(10,'fox',23);
INSERT INTO "animals" VALUES(30,'polar bear',99);
CREATE UNIQUE INDEX `animals_index0` on `animals` (`id`);}
    }
  end

  def test_replace_an_animal_with_newer_version
    # Make a temporary directory (erased at end of block)
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 }, table_name = "animals")
      ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 11 }, table_name = "animals")
      ScraperWiki.close_sqlite
      check_dump %Q{CREATE TABLE `animals` (`id` integer,`animal` text,`awesomeness` integer);
INSERT INTO "animals" VALUES(10,'fox',11);
CREATE UNIQUE INDEX `animals_index0` on `animals` (`id`);}
    }
  end

  def test_add_new_column_with_later_save
    # Make a temporary directory (erased at end of block)
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 }, table_name = "animals")
      ScraperWiki.save_sqlite(['id'], {'id'=> 40, 'animal'=> 'kitten', 'awesomeness'=> 91, 'cuteness'=> 87 }, table_name = "animals")
      ScraperWiki.close_sqlite
      check_dump %Q{CREATE TABLE `animals` (`id` integer,`animal` text,`awesomeness` integer, `cuteness` integer);
INSERT INTO "animals" VALUES(10,'fox',23,NULL);
INSERT INTO "animals" VALUES(40,'kitten',91,87);
CREATE UNIQUE INDEX `animals_index0` on `animals` (`id`);}
    }
  end


end


