require 'test/unit'
require 'scraperwiki'
require 'tmpdir'

def check_dump(expected_dump)
  actual_dump = `sqlite3 scraperwiki.sqlite .dump | egrep -v "PRAGMA foreign_keys|BEGIN TRANSACTION|COMMIT"`.strip
  expected_dump.strip!
  assert_equal actual_dump, expected_dump
end

class ScraperWikiExecuteTest < Test::Unit::TestCase
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
      ScraperWiki.close_sqlite
    }
  end

  def test_sqliteexecute_with_records
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 }, table_name = "animals")
      assert_equal ScraperWiki.sqliteexecute("select * from animals"),{"keys"=>["id", "animal","awesomeness"], "data"=>[[10, "fox",23]]}
      ScraperWiki.close_sqlite
    }
  end

  def test_sqliteexecute_without_records
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      assert_raise(SQLite3::SQLException){ScraperWiki.sqliteexecute("select * from animals")}
      ScraperWiki.close_sqlite
    }
  end

  def test_sqliteexecute_with_data_definition_statements
    Dir.mktmpdir { |dir|
      Dir.chdir dir
      ScraperWiki.sqliteexecute("create table animals(id int,animal text,awesomeness int)")
      check_dump %Q{CREATE TABLE animals(id int,animal text,awesomeness int);}
      ScraperWiki.sqliteexecute("alter table animals rename to mammals")
      check_dump %Q{CREATE TABLE "mammals"(id int,animal text,awesomeness int);}
      ScraperWiki.close_sqlite
    }
  end
end
