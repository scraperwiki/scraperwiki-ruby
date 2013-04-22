#!/usr/bin/env ruby
# TODO: Make this into an actual *test* script, not just a chunk of code

require './lib/scraperwiki.rb'

ScraperWiki.save_sqlite(['id'], {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 23 }, table_name = "foobl")
ScraperWiki.save_sqlite(['id'], {'id'=> 20, 'animal'=> 'rabbit', 'awesomeness'=> 37 }, table_name = "foobl")
ScraperWiki.save_sqlite(['id'], [
  {'id'=> 10, 'animal'=> 'fox', 'awesomeness'=> 11 },
  {'id'=> 30, 'animal'=> 'polar bear', 'awesomeness'=> 99 }
], table_name = "foobl")

