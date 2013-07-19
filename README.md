# ScraperWiki Ruby library [![Build Status](https://travis-ci.org/openc/scraperwiki-ruby.png)](https://travis-ci.org/openc/scraperwiki-ruby)

This is a Ruby library for scraping web pages and saving data. It is a fork/rewrite of the original [scraperwiki-ruby](https://github.com/scraperwiki/scraperwiki-ruby) gem, extracting the SQLite utility methods into the [sqlite_magic](https://github.com/openc/sqlite_magic) gem.

It is a work in progress (for example, it doesn't yet create indices automatically), but should allow ScraperWiki classic scripts to be run locally. 

## Installing

Add this line to your application's Gemfile:

    gem 'scraperwiki'

And then execute:

    $ bundle

## Scraping

### ScraperWiki.scrape(url[, params])

Returns the downloaded string from the given *url*. *params* are sent as a POST if set.

### Saving data

Helper functions for saving and querying an SQL database. Updates the schema
automatically according to the data you save.

Currently only supports SQLite. It will make a local SQLite database.

### ScraperWiki.save\_sqlite(unique\_keys, data[, table\_name = "swdata"],verbose)

Saves a data record into the datastore into the table given
by *table_name*.

*data* is a hash with field names as keys (can be strings or symbols).

*unique_keys* is a subset of data.keys() which determines when a record is
overwritten.

For large numbers of records *data* can be an array of hashes.

*verbose*, kept for smooth migration from classic, doesn't do anything yet.

### ScraperWiki.sqliteexecute(query,[params],verbose)

Executes provided query with the parameters against the database and returns the results in key value pairs

*query* is a sql statement

*params*, if prepared statement will contains an array of values

### ScraperWiki.save\_var(name,value,verbose)

Allows the user to save a single variable (at a time) to carry state across runs of the scraper.

*name*, the variable name

*value*, the value of the variable

*verbose*, verbosity level

### ScraperWiki.get\_var(name,default,verbose)

Allows the user to retrieve a previously saved variable

*name*, The variable name to fetch

*value*, The value to use if the variable name is not found

*verbose*, verbosity level

### ScraperWiki.select(partial\_query,[params],verbose)

Allows for a simplified select statement

*partial_query*, A valid select statement, without the select keyword

*params* Any data provided for ? replacements in the query

*verbose*, verbosity level

## Usage

Run your Ruby scraper and any data saved will be put in an SQLite database in the current directory called `scraperwiki.sqlite`.

If you're using scrapers from ScraperWiki Classic, remember to add `require 'scraperwiki'` to your file if it's not already there.

## Development

You need the `sqlite3` program installed to run tests. To install run `sudo apt-get install sqlite3` on Ubuntu.
