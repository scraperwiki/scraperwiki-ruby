require 'sqlite3'
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'scraperwiki/sqlite_save_info.rb'

module ScraperWiki

    # The scrape method fetches the content from a webserver.
    #
    # === Parameters
    #
    # * _url_ = The URL to fetch
    # * _params_ = The parameters to send with a POST request
    # * _agent = A manually supplied useragent string
    #
    # === Example
    # ScraperWiki::scrape('http://scraperwiki.com')
    #
    def ScraperWiki.scrape(url, params = nil, agent = nil)
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

    # Saves the provided data into a local database for this scraper. Data is upserted
    # into this table (inserted if it does not exist, updated if the unique keys say it 
    # does).
    #
    # === Parameters
    #
    # * _unique_keys_ = A list of column names, that used together should be unique
    # * _data_ = A hash of the data where the Key is the column name, the Value the row
    #            value.  If sending lots of data this can be a list of hashes.
    # * _table_name_ = The name that the newly created table should use.
    #
    # === Example
    # ScraperWiki::save(['id'], {'id'=>1})
    #
    def ScraperWiki.save_sqlite(unique_keys, data, table_name="swdata")
        raise 'unique_keys must be nil or an array' if unique_keys != nil && !unique_keys.kind_of?(Array)
        raise 'data must have a non-nil value' if data == nil

        # convert :symbols to "strings"
        unique_keys = unique_keys.map { |x| x.kind_of?(Symbol) ? x.to_s : x }

        if data.class == Hash
            data = [ data ]
        elsif data.length == 0
            return
        end

        rjdata = [ ]
        for ldata in data
            ljdata = _convdata(unique_keys, ldata)
            rjdata.push(ljdata)

        end

        SQLiteMagic._do_save_sqlite(unique_keys, rjdata, table_name)
    end 

    def ScraperWiki.close_sqlite()
        SQLiteMagic.close
    end

    # Internal function to check a row of data, convert to right format
    def ScraperWiki._convdata(unique_keys, scraper_data)
        if unique_keys
            for key in unique_keys
                if !key.kind_of?(String) and !key.kind_of?(Symbol)
                    return 'unique_keys must each be a string or a symbol, this one is not: ' + key
                end
                if !scraper_data.include?(key) and !scraper_data.include?(key.to_sym)
                    return 'unique_keys must be a subset of data, this one is not: ' + key
                end
                if scraper_data[key] == nil and scraper_data[key.to_sym] == nil
                    return 'unique_key value should not be nil, this one is nil: ' + key
                end
            end
        end

        jdata = { }
        scraper_data.each_pair do |key, value|
            raise 'key must not have blank name' if not key

            key = key.to_s if key.kind_of?(Symbol)
            raise 'key must be string or symbol type: ' + key if key.class != String
            raise 'key must be simple text: ' + key if !/[a-zA-Z0-9_\- ]+$/.match(key)

            # convert formats
            if value.kind_of?(Date)
                value = value.iso8601
            end
            if value.kind_of?(Time)
                value = value.iso8601
                raise "internal error, timezone came out as non-UTC while converting to SQLite format" unless value.match(/([+-]00:00|Z)$/)
                value.gsub!(/([+-]00:00|Z)$/, '')
            end
            if ![Fixnum, Float, String, TrueClass, FalseClass, NilClass].include?(value.class)
                value = value.to_s
            end

            jdata[key] = value
        end
        return jdata
    end

end
