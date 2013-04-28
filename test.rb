#!/usr/bin/env ruby
# TODO: Make this into an actual *test* script, not just a chunk of code

require './lib/scraperwiki.rb'

data = {:set_date=>"2013-04-28", :deal_id=>2493454, :company_name=>"Briefing Media Ltd", :created_at=>"2013-01-15", :updated_at=>"2013-04-25", :price=>0, :price_type=>"fixed", :currency=>"GBP", :duration=>1, :status=>"pending", :status_changed_on=>"2013-04-25", :deal_name=>"809 - Farming data", :category=>"Application Development (p)", :background=>"Just a note to keep track of this opportunity"}
ScraperWiki.save_sqlite(['set_date, deal_id'], data, table_name="highrise")



