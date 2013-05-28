ScraperWiki Ruby library
========================

This is a Ruby library for scraping web pages and saving data.

It is the easiest way to save data on the ScraperWiki platform, and it
can also be used locally or on your own servers.


Installing
==========

```
gem install scraperwiki
```

Scraping
========

ScraperWiki.scrape(url[, params])
---------------------------------

Returns the downloaded string from the given *url*. *params* are sent as a POST if set.


Saving data
===========

Helper functions for saving and querying an SQL database. Updates the schema
automatically according to the data you save.

Currently only supports SQLite. It will make a local SQLite database.
You should expect it to support other SQL databases at a later date.


ScraperWiki.save\_sqlite(unique\_keys, data[, table\_name = "swdata"],verbose)
-------------------------------------------------------------------

Saves a data record into the datastore into the table given
by *table_name*.

*data* is a hash object with field names as keys (can be strings or symbols).

*unique_keys* is a subset of data.keys() which determines when a record is
overwritten.

For large numbers of records *data* can be a list of dicts.

*verbose*, kept for smooth migration from classic, doesn't do anything yet.

ScraperWiki.sqliteexecute(query,[params],verbose)
---------------------------------

Executes provided query with the parameters against the database and returns the results in key value pairs

*query* is a sql statement
*params*, if prepared statement will contains an array of values

ScraperWiki.save_var(name,value,verbose)
---------------------------------
Allows the user to save a single variable (at a time) to carry state across runs of the scraper.

*name*, the variable name
*value*, the value of the variable
*verbose*, verbosity level

ScraperWiki.get_var(name,default,verbose)
---------------------------------
Allows the user to retrieve a previously saved variable

*name*, The variable name to fetch
*value*, The value to use if the variable name is not found
*verbose*, verbosity level
