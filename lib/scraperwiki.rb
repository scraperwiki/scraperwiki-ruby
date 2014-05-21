require 'httpclient'
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
# require 'scraperwiki/sqlite_save_info.rb'
require 'scraperwiki/version.rb'
require 'sqlite_magic'
require 'json'


module ScraperWiki
  extend self

  # The scrape method fetches the content from a webserver.
  #
  # === Parameters
  #
  # * _url_ = The URL to fetch
  # * _params_ = The parameters to send with a POST request
  # * _agent = A manually supplied useragent string
  # NB This method hasn't been refactored or tested, but could
  # prob do with both
  #
  # === Example
  # ScraperWiki::scrape('http://scraperwiki.com')
  #
  def scrape(url, params = nil, agent = nil)
    if agent
      client = HTTPClient.new(:agent_name => agent)
    else
      client = HTTPClient.new
    end
    client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    if HTTPClient.respond_to?("client.transparent_gzip_decompression=")
      client.transparent_gzip_decompression = true
    end

    if params.nil?
      html = client.get_content(url)
    else
      html = client.post_content(url, params)
    end

    unless HTTPClient.respond_to?("client.transparent_gzip_decompression=")
      begin
        gz = Zlib::GzipReader.new(StringIO.new(html))
        return gz.read
      rescue
        return html
      end
    end
  end

  def convert_data(value_data)
    return value_data if value_data.nil? or (value_data.respond_to?(:empty?) and value_data.empty?)
    [value_data].flatten(1).collect do |datum_hash|
      datum_hash.inject({}) do |hsh, (k,v)|
        hsh[k] =
          case v
          when Date, DateTime
            v.iso8601
          when Time
            # maintains existing ScraperWiki behaviour
            v.iso8601.sub(/([+-]00:00|Z)$/, '')
          else
            v
          end
        hsh
      end
    end
  end

  def config=(config_hash)
    @config ||= config_hash
  end
  # Saves the provided data into a local database for this scraper. Data is upserted
  # into this table (inserted if it does not exist, updated if the unique keys say it
  # does).
  #
  # === Parameters
  #
  # * _unique_keys_ = A list of column names, that used together should be unique
  # * _data_ = A hash of the data where the Key is the column name, the Value the row
  #            value. If sending lots of data this can be a array of hashes.
  # * _table_name_ = The name that the newly created table should use (default is 'swdata').
  # * _verbose_ = A verbosity level (not currently implemented, and there just to avoid breaking existing code)
  #
  # === Example
  # ScraperWiki::save(['id'], {'id'=>1})
  #
  def save_sqlite(unique_keys, data, table_name=nil,_verbose=0)
    table_name ||= default_table_name
    converted_data = convert_data(data)
    sqlite_magic_connection.save_data(unique_keys, converted_data, table_name)
  end

  # legacy alias for #save_sqlite method, so works with older scrapers
  def save(*args)
    save_sqlite(*args)
  end

  def sqliteexecute(query,data=nil, verbose=2)
    sqlite_magic_connection.execute(query,data)
  end

  def close_sqlite
    sqlite_magic_connection.close
    @sqlite_magic_connection = nil
  end

  # Allows the user to retrieve a previously saved variable
  #
  # === Parameters
  #
  # * _name_ = The variable name to fetch
  # * _default_ = The value to use if the variable name is not found
  # * _verbose_ = A verbosity level (not currently implemented, and there just to avoid breaking existing code)
  #
  # === Example
  # ScraperWiki.get_var('current', 0)
  #
  def get_var(name, default=nil, _verbose=2)
    result = sqlite_magic_connection.execute("select value_blob, type from swvariables where name=?", [name])
    return default if result.empty?
    result_val = result.first['value_blob']
    case result.first['type']
    when 'Fixnum'
      result_val.to_i
    when 'Float'
      result_val.to_f
    when 'NilClass'
      nil
    when 'Array','Hash'
      JSON.parse(result_val)
    else
      result_val
    end
  rescue SqliteMagic::NoSuchTable
    return default
  end

  # Allows the user to save a single variable (at a time) to carry state across runs of
  # the scraper.
  #
  # === Parameters
  #
  # * _name_ = The variable name
  # * _value_ = The value of the variable
  # * _verbose_ = A verbosity level (not currently implemented, and there just to avoid breaking existing code)
  #
  # === Example
  # ScraperWiki.save_var('current', 100)
  #
  def save_var(name, value, _verbose=2)
    val_type = value.class.to_s
    unless ['Fixnum','String','Float','NilClass', 'Array','Hash'].include?(val_type)
      puts "*** object of type #{val_type} converted to string\n"
    end
    val = val_type[/Array|Hash/] ? value.to_json : value.to_s
    data = { :name => name.to_s, :value_blob => val, :type => val_type }
    sqlite_magic_connection.save_data([:name], data, 'swvariables')
  end

  # Allows for a simplified select statement
  #
  # === Parameters
  #
  # * _sqlquery_ = A valid select statement, without the select keyword
  # * _data_ = Bind variables provided for ? replacements in the query. See Sqlite3#execute for details
  # * _verbose_ = A verbosity level (not currently implemented, and there just to avoid breaking existing code)
  # * [optionally] a block can be also be passed and the result rows will be passed
  # one-by-one to the black rather than loading and returning the whole result set
  #
  # === Returns
  # An array of hashes containing the returned data
  #
  # === Example
  # ScraperWiki.select('* from swdata')
  #
  def select(sqlquery, data=nil, _verbose=1)
    if block_given?
      sqlite_magic_connection.database.
                              query("SELECT "+sqlquery, data).
                              each_hash do |row_hash|
         yield row_hash
      end
    else
      sqlite_magic_connection.execute("SELECT "+sqlquery, data)
    end
  end

  # Establish an SQLiteMagic::Connection (and remember it)
  def sqlite_magic_connection
    db = @config ? @config[:db] : 'scraperwiki.sqlite'
    @sqlite_magic_connection ||= SqliteMagic::Connection.new(db)
  end

  def default_table_name
    (@config && @config[:default_table_name]) || 'swdata'
  end

end
