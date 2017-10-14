module Nekonote
    class Request
        STRING  = 'string'
        INTEGER = 'int'
        ARRAY   = 'array'
        FLOAT   = 'float'
        BOOL    = 'bool'

        # accessor
        attr_reader :path,
                    :uri,
                    :method,
                    :payload

        # @param hash env
        # @param string|nil restricted
        def initialize(env, restricted = nil)
            # set properties
            @path   = env['REQUEST_PATH']
            @uri    = env['REQUEST_URI']
            @method = env['REQUEST_METHOD']
            @accepted_list = get_accepted_list restricted

            # query string
            @query_string     = {}
            @query_string_raw = {}

            # POST data
            @post_data     = {}
            @post_data_raw = {}

            # URL path parameters
            @path_params     = {}
            @path_params_raw = {}

            # request body
            @payload = nil

            # set query string
            if env['QUERY_STRING'].is_a? String
                @query_string_raw = get_param_maps env['QUERY_STRING']
                @query_string     = get_sanitized @query_string_raw
            end

            # set POST data
            if env['rack.input'].is_a? StringIO
                @post_data_raw = get_param_maps env['rack.input'].gets
                @post_data     = get_sanitized @post_data_raw
            end
        end

        # Returns sanitized query string
        # @params string|symbol name
        # @return mixed
        public
        def query_string(name = nil)
            return get_value name, @query_string
        end

        # Returns raw query string
        # @params string|symbol name
        # @return mixed
        public
        def query_string_raw(name = nil)
            return get_value name, @query_string_raw
        end

        # Returns sanitized POST data
        # @params string|symbol name
        # @return mixed
        public
        def post_data(name = nil)
            return get_value name, @post_data
        end

        # Returns raw POST data
        # @params string|symbol name
        # @return mixed
        public
        def post_data_raw(name = nil)
            return get_value name, @post_data_raw
        end

        # Returns sanitized URL parameters
        # @params string|symbol name
        # @return mixed
        public
        def path_params(name = nil)
            return get_value name, @path_params
        end

        # Returns raw URL parameters
        # @params string|symbol name
        # @return mixed
        public
        def path_params_raw(name = nil)
            return get_value name, @path_params_raw
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

        # Returns raw parameters
        # @params string|symbol name
        # @return mixed
        public
        def params_raw(name = nil)
            case @method
            when 'GET'
                maps = @query_string_raw
            when 'POST'
                maps = @post_data_raw
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
            @path_params_raw = map
            @path_params     = get_sanitized @path_params_raw
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

        # Returns the accepable name list
        # @param string|nil restricted
        # @return array
        private
        def get_accepted_list(restricted)
            accepted_list = []
            if restricted.is_a? String
                restricted.split(',').each do |data|
                    data.strip!
                    pair = data.split('=')
                    if pair.size != 2
                        raise Error, Error::MSG_INVALID_FIELD%['params', Preference.instance.path_route_yml]
                    end
                    # add field name and hash as Hash into array
                    accepted_list << {pair[0] => pair[1]}
                end
            end

            return accepted_list
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

        # Removing waste parameter and converting to the exected type
        # @param hash maps
        # @param bool decode
        # @return hash
        private
        def get_sanitized(maps, decode = false)
            return maps if @accepted_list.size == 0

            sanitized_maps = {}
            @accepted_list.each do |field|
                field.each_pair do |name, type|
                    converted = get_expected type, maps[name]

                    # URL decode if necessary
                    if decode || converted.is_a?(String)
                        converted = URI.decode_www_form_component converted
                    end

                    sanitized_maps[name] = converted
                end
            end

            return sanitized_maps
        end

        # @param string type type expected
        # @param mixed value real value
        # @param string converted value by the expected type
        private
        def get_expected(type, value)
            return nil if value == nil

            v = nil
            begin
                case type
                when INTEGER
                    v = value.to_i
                when STRING
                    v = value.to_s
                when ARRAY
                    v = value.to_s.split(',')
                    v.map! { |val| val.strip }
                when FLOAT
                    v = value.to_f
                when BOOL
                    if value == nil || value == false || value == 'false' || value == 0 || value == '0' || value == 'no' || value == ''
                        v = false
                    else
                        v = true
                    end
                end
            rescue
                # value is nil if failed to convert value to expected type
            end

            return v
        end
    end
end
