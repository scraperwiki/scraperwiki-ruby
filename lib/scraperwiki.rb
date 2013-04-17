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


end
