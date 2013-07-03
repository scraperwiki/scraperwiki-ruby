require 'httpclient'
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
# require 'scraperwiki/sqlite_save_info.rb'
require 'scraperwiki/version.rb'
require 'sqlite_magic'

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
  def save_sqlite(unique_keys, data, table_name="swdata",_verbose=0)
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
    result_val = result.first[:value_blob]
    case result.first[:type]
    when 'Fixnum'
      result_val.to_i
    when 'Float'
      result_val.to_f
    when 'NilClass'
      nil
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
    unless ['Fixnum','String','Float','NilClass'].include?(val_type)
      puts "*** object of type #{val_type} converted to string\n"
    end

    data = { :name => name.to_s, :value_blob => value.to_s, :type => val_type }
    sqlite_magic_connection.save_data([:name], data, 'swvariables')
  end

  # Allows for a simplified select statement
  #
  # === Parameters
  #
  # * _sqlquery_ = A valid select statement, without the select keyword
  # * _data_ = Bind variables provided for ? replacements in the query. See Sqlite3#execute for details
  # * _verbose_ = A verbosity level (not currently implemented, and there just to avoid breaking existing code)
  #
  # === Returns
  # An array of hashes containing the returned data
  #
  # === Example
  # ScraperWiki.select('* from swdata')
  #
  def select(sqlquery, data=nil, _verbose=1)
    sqlite_magic_connection.execute("SELECT "+sqlquery, data)
  end

  # Establish an SQLiteMagic::Connection (and remember it)
  def sqlite_magic_connection
    @sqlite_magic_connection ||= SqliteMagic::Connection.new
  end

end
