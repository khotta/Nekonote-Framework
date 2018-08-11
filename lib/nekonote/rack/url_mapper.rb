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
      end

      return url_path_params_mapper, pattern
    end

    # @param string pattern
    # @returns regexp, hash, string
    def get_route_regexp(pattern)
      # if home page
      pattern = '/' if pattern == ''

      # escape special meaning characters in regexp
      pattern = Regexp.quote pattern

      # parse path for url path parameters
      url_path_params_mapper, pattern = parse_url_path_params pattern

      pattern = %(^#{pattern}$)

      # If duplocate slashes are allowed change regexp a little bit for it
      if Preference.instance.is_allow_dup_slash?
          pattern.gsub! '/', '/+'
      end

      match = Regexp.new pattern, nil, 'n'

      return match, url_path_params_mapper, pattern
    end

    # @param string pattern
    # @returns regexp, hash, string
    def get_route_regexp_custom(pattern)
      option = nil
      code   = nil

      # parse path for url path parameters
      url_path_params_mapper, pattern = parse_url_path_params pattern

      if pattern == ''
        # home page
        pattern = '/$'

      elsif /\/[ixmn]+$/ =~ pattern
        # there is regexp option
        matched_str = $&.delete '/'
        pattern     = pattern.sub /\/[ixmn]+$/, ''
        option = 0
        matched_str.each_char do |char|
          case char
          when 'i'
            option = option | Regexp::IGNORECASE
          when 'm'
            option = option | Regexp::MULTILINE
          when 'x'
            option = option | Regexp::EXTENDED
          when 'n'
            code = 'n'
          end
        end
      end

      pattern = '^' + pattern

      # If duplocate slashes are allowed change regexp a little bit for it
      if Preference.instance.is_allow_dup_slash?
          pattern.gsub! '/', '/+'
      end

      match = Regexp.new pattern, option, code

      return match, url_path_params_mapper, pattern
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
        if Preference.instance.is_path_regexp?
          match, url_path_params_mapper, location = get_route_regexp_custom location # path will be evaluated as regexp
        else
          match, url_path_params_mapper, location = get_route_regexp location
        end

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
