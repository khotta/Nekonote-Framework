module Nekonote
    class Request
        # accessor
        attr_reader :path,
                    :uri,
                    :method,
                    :payload

        # @param hash env
        def initialize(env)
            # set properties
            @path   = env['REQUEST_PATH']
            @uri    = env['REQUEST_URI']
            @method = env['REQUEST_METHOD']

            # query string
            @query_string = {}

            # POST data
            @post_data = {}

            # URL path parameters
            @path_params = {} # this will be set from handler

            # request body
            @payload = nil

            # set query string
            if env['QUERY_STRING'].is_a? String
                @query_string = get_param_maps env['QUERY_STRING']
            end

            # set POST data
            if env['rack.input'].is_a? StringIO
                @post_data = get_param_maps env['rack.input'].gets
            end
        end

        # Returns query string
        # @params string|symbol name
        # @return mixed
        public
        def query_string(name = nil)
            return get_value name, @query_string
        end

        # Returns POST data
        # @params string|symbol name
        # @return mixed
        public
        def post_data(name = nil)
            return get_value name, @post_data
        end

        # Returns URL parameters
        # @params string|symbol name
        # @return mixed
        public
        def path_params(name = nil)
            return get_value name, @path_params
        end

        # Returns sanitized parameters
        # @params string|symbol name
        # @return mixed
        public
        def params(name = nil)
            case @method
            when 'GET'
                maps = @query_string
            when 'POST'
                maps = @post_data
            else
                maps = {}
            end
            return get_value name, maps
        end

        # Returns parsed payload as json format
        # @return hash|nil|false
        public
        def json_payload
            if @payload != nil
                begin
                    parsed = JSON.parse @payload
                rescue
                    # unable to parse
                    parsed = false
                end
            else
                # no payload given
                parsed = nil
            end

            return parsed
        end

        # @param hash map
        public
        def assign_from_url(map)
            return nil if !map.is_a? Hash

            # set url params
            @path_params = map
        end

        # @param mixed payload
        public
        def set_payload(payload)
            @payload = payload
        end

        # @param string|symbol name
        # @return bool
        public
        def valid_str?(name)
            params(name) != nil && params(name) != ''
        end

        # @param string|symbol name
        public
        def having?(name)
            params(name) != nil
        end

        # @param string|symbol name
        # @param hash maps
        # @return mixed
        private
        def get_value(name, maps)
            if name.is_a? String
                return maps[name]

            elsif name.is_a? Symbol
                return maps[name.to_s]

            else
                return maps
            end
        end

        # @param string str query string
        # @return hash
        private
        def get_param_maps(str)
            maps = {}
            return maps if !str.is_a? String

            str.split('&').each do |field|
                pair = field.split('=')
                if pair.size == 2
                    v = pair[1]
                else
                    v = nil
                end
                maps[pair[0]] = v
            end

            return maps
        end
    end
end
