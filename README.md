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


ScraperWiki.save\_sqlite(unique\_keys, data[, table\_name = "swdata"],verbose = 0)
-------------------------------------------------------------------

Saves a data record into the datastore into the table given
by *table_name*.

*data* is a hash object with field names as keys (can be strings or symbols).

*unique_keys* is a subset of data.keys() which determines when a record is
overwritten.

For large numbers of records *data* can be a list of dicts.

*verbose*, kept for smooth migration from classic, doesn't do anything yet.
