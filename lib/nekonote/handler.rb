module Nekonote
    class Handler
        EXIT = 'Nekonote exit from queue'
        require Nekonote.get_lib_root_path + 'handler/protected_methods'
        include ProtectedMethods

        # =============================================
        # Accessors
        # =============================================
        attr_accessor :route_regexp,
                      :url_path_params_mapper

        # =============================================
        # Static method
        # =============================================
        # make error handler and execute it
        # @param string field
        # @param hash env
        # @param nil e
        # @return array
        def self.call_error_handler(field, env = {}, e = nil)
            pref = Preference.instance.get_route_error

            # field is expected String and pref[field] is expected Hash
            if !field.is_a?(String) || !pref[field].is_a?(Hash)
                raise HandlerError, HandlerError::MSG_MISSING_FIELD%[field, Preference.instance.path_route_error_yml]
            end

            # make handler newly
            handler_name = pref[field][Preference::FIELD_ROUTE_HANDLER]
            if handler_name.is_a? String
                begin
                    handler_class = Object.const_get handler_name
                    error_handler = handler_class.new pref[field].clone, field, e
                rescue
                    raise HandlerError, HandlerError::MSG_MISSING_CONST% handler_name
                end
            else
                raise HandlerError, HandlerError::MSG_MISSING_ERR_HANDLER
            end

            return error_handler.call env
        end


        # It would be called only one time
        # @param hash info route information
        # @param bool|nil error_field_name
        # @param StandardError error
        def initialize(info={}, error_field_name = nil, error = nil)
            # Both the properties are allowed to access in sub classes
            @view = View.new (info || {}), self.class.to_s, error_field_name

            @request      = nil # Object of Nekonote::Request
            @session      = nil # Object about session management
            @route_regexp = nil # Object of Regexp
            @url_path_params_mapper = nil # Hash

            # exception object will be set if fatal error occured
            @error = error

            # custom fields will be set, if no custom field just {} will be set
            @custom_fields = Preference.get_custom_fields info, error_field_name.is_a?(String)
        end

        # reload preferences
        private
        def pref_reloader
            path = Nekonote.get_root_path + Preference::FILE_NAME_FOR_RELOAD
            if File.exist? path
                # reload logger
                Nekonote.init_logger

                # reload setting
                Setting.init

                Util::Filer::safe_delete_empty_file path
            end
        end

        # This method would be called from rack and called in every request
        # @param hash env rack environment
        public
        def call(env)
            # reload preferences if needed
            pref_reloader

            # get reponse data from page cache if it's available
            if @view.can_get_from_page_cache?(env['REQUEST_URI'])
                response_data = @view.get_response_data_from_page_cache env['REQUEST_URI']
                if response_data.size == 3
                    # return the cache
                    return response_data
                else
                    # invalid page cache file, put warning message
                    Error.warning 'Wrong page cache file was detected. Please remove page cache.'
                end
            end

            # initialize response
            @view.init_for_response

            # set env to Nekonote::env
            Env.set_rackenv env

            # set session if it's enabled
            @session = Env.get 'rack.session'

            # set request
            @request = Request.new env, @view.info_params

            # set request body to request object if it exists
            if env['rack.input'].is_a? StringIO
                # reverting file pointer I don't know why the pointer moved just one...?
                env['rack.input'].rewind
                @request.set_payload env['rack.input'].read
            end

            # execute
            if !@view.is_error_route
                begin
                    return execute env

                rescue StandardError, ScriptError => e
                    # fatal error occured
                    process_exception_raised e

                    # if ShowExceptions is disabled and fatal error route has been defined, forward custom error page
                    if Preference.instance.has_error_route? Preference::FIELD_ROUTE_ERR_FATAL
                        return Handler.call_error_handler Preference::FIELD_ROUTE_ERR_FATAL, Env.get_all, e
                    end
                end

            else
                # If self is Handler for error routes
                begin
                    execute_handler_methods @view.info_exec_method
                    return get_response_data

                rescue StandardError, ScriptError => e
                    process_exception_raised e
                end
            end

            # in the case of an exception raised but
            # there is no fatal error route OR the exception raised in fatal error route
            # and also ShowExceptons does not handle an exception
            # returns an empty response
            # TODO Do I have to change them to be customizable?
            return View.get_default_error_response
        end

        # @param StandardError|ScriptError e
        # @throws StandardError|ScriptError
        private
        def process_exception_raised(e)
            # logging if logger is enabled
            Error.logging_error e

            # raise the exception for ShowExceptions if it's enabled
            raise e if Preference.instance.is_enabled_show_exceptions
        end

        # It would be called by every request
        # @param hash env
        # @return array
        #     response_code   int
        #     response_header hash
        #     response_body   array
        private
        def execute(env)
            # check path machs the expected path
            if matched_route_strictly? @request.path, @view.info_path
                # check request HTTP method
                if is_allowed_http_method @request.method
                    # matched some route then call methods defined in concrete handlers
                    execute_handler_methods @view.info_exec_method
                else
                    # request method error
                    return Handler.call_error_handler Preference::FIELD_ROUTE_ERR_WRONG_METHOD, Env.get_all
                end

            else
                # doesn't match any routes
                return Handler.call_error_handler Preference::FIELD_ROUTE_ERR_MISSING_ROUTE, Env.get_all
            end

            return get_response_data
        end

        # Check does requested path correspond with the given value to #map
        # @return bool
        private
        def matched_route_strictly?(requested_path, expected_path)
            match_data = @route_regexp.match requested_path
            if match_data.is_a? MatchData
                # set URL path parameters to Request object
                if @url_path_params_mapper.is_a? Hash
                    stack = requested_path.split('/')
                    map   = {}
                    @url_path_params_mapper.each_pair do |name, index|
                        map[name] = stack[index] 
                    end
                    @request.assign_from_url map
                end

                return true

            else
                # doesn't match, the requested path is wrong
                return false
            end
        end

        # Get response data and return values as rack needed
        # @return array
        private
        def get_response_data
            # return response if redirection
            if @view.is_redirect
                return @view.get_response_data
            end

            # set response body with template and/or layout when response body hasn't been set by __set_body
            @view.set_body_with_tpl if !@view.is_body_set?

            # make page cache file if need it
            if @view.need_create_page_cache? @request.uri
                @view.create_page_cache @request.uri
            end

            return @view.get_response_data
        end

        # @param string|symbol|nil task method name defined in 'klass'
        private
        def execute_handler_methods(task)
            if task != nil && !task.is_a?(String) && !task.is_a?(Symbol)
                raise HandlerError, HandlerError::MSG_WRONG_TYPE%[task.class, 'String|Symbol|nil']
            end

            # execute methods when it's defined
            # if __pre is defined execute it first
            return if execute_method(:__pre, self) == EXIT
            # execute particular method specified with routes.yml when it isn't nil
            return if execute_method(task, self) == EXIT
            # if __post is defined execute it last
            execute_method :__post, self
        end

        # @param method symbol|string
        private
        def execute_method(method, handler)
            if !@view.is_redirect && (method != nil) && handler.respond_to?(method, true)
                handler.method(method).call
            end
        end

        # Is given method allowed?
        # @pram string method
        # @return false|nil|int
        private
        def is_allowed_http_method(method)
            return false if !method.is_a? String
            http_methods = @view.info_allow_methods
            return true if http_methods == nil
            http_methods = http_methods.split(',')
            http_methods.map! do |val|
                val.strip
            end
            return http_methods.index method
        end
    end
end
