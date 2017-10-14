module Nekonote
    class Preference
        include Singleton

        # hidden file name for reloading preferences
        FILE_NAME_FOR_RELOAD = '.reload_preference'

        # for route.yml
        FIELD_ROUTE_INCLUDE = 'include'

        # for route options
        FIELD_OPTION_ROUTE = 'preference'
        FIELD_OPTION_ROUTE_REGEXP    = 'path_as_regexp'
        FIELD_OPTION_ALLOW_DUP_SLASH = 'allow_dup_slash'

        # for route_error.yml
        FIELD_ROUTE_ERR_MISSING_ROUTE = 'missing_route'
        FIELD_ROUTE_ERR_WRONG_METHOD  = 'wrong_http_method'
        FIELD_ROUTE_ERR_FATAL         = 'fatal'
        FIELD_ROUTE_ERR_NOT_FOUND     = 'not_found'

        # for route.yml and route_error.yml
        FIELD_ROUTE_PATH            = 'path'
        FIELD_ROUTE_EXEC_METHOD     = 'execute'
        FIELD_ROUTE_ALLOW_METHODS   = 'method'
        FIELD_ROUTE_PARAMS          = 'params'
        FIELD_ROUTE_CONTENT_TYPE    = 'content'
        FIELD_ROUTE_TEMPLATE        = 'template'
        FIELD_ROUTE_LAYOUT          = 'layout'
        FIELD_ROUTE_PAGE_CACHE_TIME = 'page_cache_time'
        FIELD_ROUTE_HANDLER         = 'handler'

        # Except these fields are custom fields
        FIELDS_IN_ROUTE = [
            FIELD_ROUTE_PATH,
            FIELD_ROUTE_EXEC_METHOD,
            FIELD_ROUTE_ALLOW_METHODS,
            FIELD_ROUTE_PARAMS,
            FIELD_ROUTE_CONTENT_TYPE,
            FIELD_ROUTE_TEMPLATE,
            FIELD_ROUTE_LAYOUT,
            FIELD_ROUTE_PAGE_CACHE_TIME,
            FIELD_ROUTE_HANDLER
        ]
        FIELDS_IN_ROUTE_ERROR = [
            FIELD_ROUTE_HANDLER,
            FIELD_ROUTE_EXEC_METHOD,
            FIELD_ROUTE_CONTENT_TYPE,
            FIELD_ROUTE_TEMPLATE,
            FIELD_ROUTE_LAYOUT,
            FIELD_ROUTE_PAGE_CACHE_TIME
        ]

        # allowed to read or write from context of outside
        attr_accessor :is_enabled_show_exceptions

        # only reading is allowed
        attr_reader :path_route_yml,
                    :path_route_include_yml,
                    :path_route_error_yml,
                    :path_public_yml,
                    :path_middlewares_rb,
                    :path_logger_yml

        def initialize
            env  = Nekonote.get_env
            path = Nekonote.get_root_path + YamlAccess::DIR_PREFERENCE + "/#{env}/"

            @path_route_yml         = path + 'route.yml'
            @path_route_include_yml = path + 'route_include.yml'
            @path_route_error_yml   = path + 'route_error.yml'
            @path_public_yml        = path + 'public.yml'
            @path_middlewares_rb    = path + 'middlewares.rb'
            @path_logger_yml        = path + 'logger.yml'

            @parsed_route_yml         = nil
            @parsed_route_include_yml = nil
            @parsed_route_error_yml   = nil
            @parsed_public_yml        = nil
            @parsed_mw_yml            = nil
            @parsed_logger_yml        = nil

            # in route.yml
            @is_path_regexp     = nil
            @is_allow_dup_slash = nil

            # in middleware.yml
            @is_enabled_show_exceptions = nil

            # check there are required yaml files
            if !Util::Filer.available_file? 'config.ru'
                msg  = Error::MSG_MISSING_RACKUP% @@root_path + $/
                msg += Error::SPACE + Error::MSG_WRONG_ROOT
                raise Error, msg
            end

            if !Util::Filer.available_file? @path_route_yml
                raise PreferenceError, Error::MSG_MISSING_FILE% @path_route_yml
            end
        end

        # @param string field
        # @return bool
        public
        def has_error_route?(field)
            pref = get_route_error

            # missing route_error.yml
            if pref == nil
                Error.warning "Missing a file which for error routes #{@path_route_error_yml}."
                return false
            end

            return pref[field].is_a?(Hash) && pref[field][FIELD_ROUTE_HANDLER].is_a?(String)
        end

        # @param bool fresh
        # @return hash or exit from program
        public
        def get_route(fresh = false)
            if !@parsed_route_yml.is_a?(Hash) || fresh
                @parsed_route_yml = YamlAccess::get_parsed_route @path_route_yml
                if @parsed_route_yml.size == 0
                    raise PreferenceError, PreferenceError::MSG_EMPTY_YAML% @path_route_yml
                end
            end
            return @parsed_route_yml
        end

        # @param bool fresh
        # @return hash
        public
        def get_route_include(fresh = false)
            if !@parsed_route_include_yml.is_a?(Hash) || fresh
                @parsed_route_include_yml = YamlAccess::get_parsed @path_route_include_yml
            end
            return @parsed_route_include_yml
        end

        # @param bool fresh
        # @return hash
        public
        def get_route_error(fresh = false)
            if !@parsed_route_error_yml.is_a?(Hash) || fresh
                @parsed_route_error_yml = YamlAccess::get_parsed @path_route_error_yml
            end
            return @parsed_route_error_yml
        end

        # @param bool fresh
        # @return hash
        public
        def get_public(fresh = false)
            if !@parsed_public_yml.is_a?(Hash) || fresh
                @parsed_public_yml = YamlAccess::get_parsed @path_public_yml
            end
            return @parsed_public_yml
        end

        # @param bool fresh
        # @return hash
        public
        def get_logger(fresh = false)
            if !@parsed_logger_yml.is_a?(Hash) || fresh
                @parsed_logger_yml = YamlAccess::get_parsed @path_logger_yml
            end
            return @parsed_logger_yml
        end

        # @param bool fresh
        # @return bool
        public
        def is_path_regexp?(fresh = false)
            if @is_path_regexp == nil || fresh
                pref = YamlAccess::get_parsed @path_route_yml

                if pref[FIELD_OPTION_ROUTE].is_a?(Hash) \
                    && (pref[FIELD_OPTION_ROUTE][FIELD_OPTION_ROUTE_REGEXP] == true || pref[FIELD_OPTION_ROUTE][FIELD_OPTION_ROUTE_REGEXP] == 1)
                    @is_path_regexp = true # using Nekonote::URLMapper
                else
                    @is_path_regexp = false # using ::Rack::URLMap
                end
            end

            return @is_path_regexp
        end

        # @param bool fresh
        # @return bool
        public
        def is_allow_dup_slash?(fresh = false)
            if @is_allow_dup_slash == nil || fresh
                pref = YamlAccess::get_parsed @path_route_yml
                if pref[FIELD_OPTION_ROUTE].is_a?(Hash) && pref[FIELD_OPTION_ROUTE][FIELD_OPTION_ALLOW_DUP_SLASH] != nil
                    @is_allow_dup_slash = pref[FIELD_OPTION_ROUTE][FIELD_OPTION_ALLOW_DUP_SLASH]
                else
                    @is_allow_dup_slash = false
                end
            end

            return @is_allow_dup_slash
        end

        # @param array info information about route
        # @param bool is_error_route
        def self.get_custom_fields(info, is_error_route = false)
            except_fields = is_error_route ? FIELDS_IN_ROUTE_ERROR : FIELDS_IN_ROUTE
            except_fields.each do |field_name|
                info.delete field_name
            end

            return info
        end
    end
end
