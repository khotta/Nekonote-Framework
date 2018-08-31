# This class is forked from rack/urlmap.rb
# Constant values in core source must be prefixed namespace.
# Allows using 2-space indentation in this class because of Rack using 2-space indentation
module Nekonote
  class URLMapper < ::Rack::URLMap
    # =========================================================================
    # Start adding source code for Nekonote Framework
    # =========================================================================
    # @param string pattern
    # @returns hash, string
    def parse_url_path_params(pattern)
      url_path_params_mapper = {}
      # change variables in path to wild card
      if /:.+/ =~ pattern
        pattern.split('/').each_with_index do |inspection, index|
          inspection.scan(/(?<=:).+/).each do |v|
            url_path_params_mapper[v] = index
          end
        end

        # replace variable with wildcard
        url_path_params_mapper.each_key do |name|
          pattern.sub! (':' + name), '.+'
        end

        # todo think in case of "path: /path/to/:something" -> It can match /path/to/foo/bar with {"something"=>"foo"}
      end

      return url_path_params_mapper, pattern
    end

    # @param string path
    # @returns regexp, hash, string
    def get_route_regexp_custom(path)
      # parse path for url path parameters
      url_path_params_mapper, path = parse_url_path_params path

      if path == ''
        # home page, it doesn't matter '' or '/'
        pattern = /^\/?$/
      else
        pattern = /^#{path}$/
      end

      return pattern, url_path_params_mapper
    end
    # =========================================================================
    # End adding source code
    # =========================================================================

    def remap(map)
      @mapping = map.map { |location, app|
        if location =~ %r{\Ahttps?://(.*?)(/.*)}
          host, location = $1, $2
        else
          host = nil
        end

        unless location[0] == ?/
          raise ArgumentError, %(Values for 'path' directive need to be started from /)
        end

        location = location.chomp('/')
        #match = Regexp.new("^#{Regexp.quote(location).gsub('/', '/+')}(.*)", nil, 'n') # comment out of original source
        # =========================================================================
        # Start adding source code for Nekonote Framework
        # =========================================================================
        # get regexp for matching URL
        # path will be evaluated as regexp
        match, url_path_params_mapper = get_route_regexp_custom location

        # set the values to Nekonote::Handler class
        app.route_regexp = match
        app.url_path_params_mapper = url_path_params_mapper
        # =========================================================================
        # End adding source code
        # =========================================================================

        [host, location, match, app]
      }.sort_by do |(host, location, _, _)|
        [host ? -host.size : ::Rack::URLMap::INFINITY, -location.size]
      end
    end

    def call(env)
      path        = env[::Rack::PATH_INFO]
      script_name = env[::Rack::SCRIPT_NAME]
      http_host   = env[::Rack::HTTP_HOST]
      server_name = env[::Rack::SERVER_NAME]
      server_port = env[::Rack::SERVER_PORT]

      is_same_server = casecmp?(http_host, server_name) ||
                       casecmp?(http_host, "#{server_name}:#{server_port}")

      @mapping.each do |host, location, match, app|
        unless casecmp?(http_host, host) \
            || casecmp?(server_name, host) \
            || (!host && is_same_server)
          next
        end

        next unless m = match.match(path.to_s)

        rest = m[1]
        next unless !rest || rest.empty? || rest[0] == ?/
        env[::Rack::SCRIPT_NAME] = (script_name + location)
        env[::Rack::PATH_INFO] = rest

        return app.call(env)
      end

      # [404, {::Rack::CONTENT_TYPE => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{path}"]] comment out of original source
      # =========================================================================
      # Start adding source code for Nekonote Framework
      # =========================================================================
      if Preference.instance.has_error_route? Preference::FIELD_ROUTE_ERR_MISSING_ROUTE
        # "missing_route" route has been defined
        begin
          # display custom error response
          return ::Nekonote::Handler.call_error_handler Preference::FIELD_ROUTE_ERR_MISSING_ROUTE, env
        rescue => e
          Error.logging_error e
          # error, default behavior
          [404, {::Rack::CONTENT_TYPE => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{path}"]]
        end

      else
        # no error route, default behavior
        [404, {::Rack::CONTENT_TYPE => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{path}"]]
      end
      # =========================================================================
      # End adding source code for Nekonote Framework
      # =========================================================================

    ensure
      env[::Rack::PATH_INFO]   = path
      env[::Rack::SCRIPT_NAME] = script_name
    end
  end # class URLMapper
end # module Nekonote
