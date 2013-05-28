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

  def test_unique_key_not_in_list
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      data = {:set_date=>"2013-04-28", :deal_id=>2493454, :company_name=>"Foo Bar Ltd", :created_at=>"2013-01-15", :updated_at=>"2013-04-25", :price=>0, :price_type=>"fixed", :currency=>"GBP", :duration=>1, :status=>"pending", :status_changed_on=>"2013-04-25", :deal_name=>"809 - Farming data", :category=>"Application Development (p)", :background=>"Just a note to keep track of this opportunity"}
      # note, we've accidentally quoted a pair of unique keys in one string
      begin
        ScraperWiki.save_sqlite(['set_date, deal_id'], data, table_name="highrise")
      rescue RuntimeError =>e
        assert_equal "unique_keys must be a subset of data, this one is not: set_date, deal_id", e.message
      end
    }
  end

  def test_new_columns_with_new_keys
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 }, table_name = "animals")
      ScraperWiki.save_sqlite(['id'], {'id'=> 40, 'animal'=> 'kitten', 'awesomeness'=> 91, 'cuteness'=> 87 }, table_name = "animals")
      ScraperWiki.close_sqlite
      check_dump %Q{CREATE TABLE `animals` (`id` integer,`animal` text,`awesomeness` integer, `cuteness` integer);
INSERT INTO "animals" VALUES(10,'fox',23,NULL);
INSERT INTO "animals" VALUES(40,'kitten',91,87);
CREATE UNIQUE INDEX `animals_index0` on `animals` (`id`);}

      ## Now add new set of data
      ScraperWiki.save_sqlite(['link'], {'link'=> "http://dummy.com/fox.html", 'animal'=> 'fox', 'meat'=> 50, "edible"=> "False" }, table_name = "animals")
      ScraperWiki.close_sqlite
      check_dump %Q{CREATE TABLE `animals` (`id` integer,`animal` text,`awesomeness` integer, `cuteness` integer, `link` text, `meat` integer, `edible` text);
INSERT INTO "animals" VALUES(10,'fox',23,NULL,NULL,NULL,NULL);
INSERT INTO "animals" VALUES(40,'kitten',91,87,NULL,NULL,NULL);
INSERT INTO "animals" VALUES(NULL,'fox',NULL,NULL,'http://dummy.com/fox.html',50,'False');
CREATE UNIQUE INDEX `animals_index1` on `animals` (`link`);}
    }
  end

  def test_dql
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.save_sqlite(['id'],{"id"=>1,"name"=>"abc"})
      ScraperWiki.save_sqlite(['id'],{"id"=>2,"name"=>"def"})
      assert_equal ScraperWiki.sqliteexecute("select * from swdata"),{"keys"=>["id", "name"], "data"=>[[1, "abc"], [2, "def"]]}
      ScraperWiki.close_sqlite
    }
  end

  def test_session_state
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ##Check the save
      ScraperWiki.save_var("scraperwiki","awesome")
      check_dump %Q{CREATE TABLE `swvariables` (`name` text,`value_blob` text,`type` text);
INSERT INTO "swvariables" VALUES('scraperwiki','awesome','String');
CREATE UNIQUE INDEX `swvariables_index0` on `swvariables` (`name`);}

      ##Check the retrieval 
      assert_equal ScraperWiki.get_var("scraperwiki"),"awesome"
      assert_equal ScraperWiki.get_var("none"),nil
    }
  end
end


