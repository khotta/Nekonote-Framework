module Nekonote
    class Preference
        include Singleton

        # hidden file name for reloading preferences
        FILE_NAME_FOR_RELOAD = '.reload_preference'

        # for route.yml
        FIELD_ROUTE_INCLUDE = 'include'

        # default values for routing options
        DEFAULT_OPTION_TEMPLATE_FILE_EXT = 'tpl'
        DEFAULT_OPTION_LAYOUT_FILE_EXT   = 'tpl'

        # for route_error.yml
        FIELD_ROUTE_ERR_MISSING_ROUTE = 'missing_route'
        FIELD_ROUTE_ERR_WRONG_METHOD  = 'wrong_http_method'
        FIELD_ROUTE_ERR_FATAL         = 'fatal'
        FIELD_ROUTE_ERR_NOT_FOUND     = 'not_found'

        # for route.yml and route_error.yml
        FIELD_ROUTE_PATH            = 'path'
        FIELD_ROUTE_EXEC_METHOD     = 'execute'
        FIELD_ROUTE_ALLOW_METHOD    = 'method'
        FIELD_ROUTE_CONTENT_TYPE    = 'content'
        FIELD_ROUTE_TEMPLATE        = 'template'
        FIELD_ROUTE_LAYOUT          = 'layout'
        FIELD_ROUTE_PAGE_CACHE_TIME = 'page_cache_time'
        FIELD_ROUTE_HANDLER         = 'handler'

        # Except these fields are custom fields
        FIELDS_IN_ROUTE = [
            FIELD_ROUTE_PATH,
            FIELD_ROUTE_EXEC_METHOD,
            FIELD_ROUTE_ALLOW_METHOD,
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
            path = Nekonote.get_root_path + YamlAccess::DIR_PREFERENCE + "/#{Nekonote.get_env}/"

            @path_route_yml         = path + 'route.yml'
            @path_route_include_yml = path + 'route_include.yml'
            @path_route_error_yml   = path + 'route_error.yml'
            @path_public_yml        = path + 'public.yml'
            @path_middlewares_rb    = path + 'middlewares.rb'
            @path_logger_yml        = path + 'logger.yml'

            # check if GUI debugger is on? this value will be set from rackup
            @is_enabled_show_exceptions = nil

            # check if config.ru and route.yml exists
            if !Util::Filer.available_file? 'config.ru'
                msg  = Error::MSG_MISSING_RACKUP% @@root_path + $/
                msg += Error::SPACE + Error::MSG_WRONG_ROOT
                raise Error, msg
            elsif !Util::Filer.available_file? @path_route_yml
                raise PreferenceError, Error::MSG_MISSING_FILE% @path_route_yml
            end

            # read preferences from configuration files
            init_pref
        end

        # @return hash
        # @throws PreferenceError
        public
        def get_route
            return @parsed_route_yml
        end

        # @return hash
        public
        def get_route_include
            return @parsed_route_include_yml
        end

        # @return hash
        public
        def get_route_error
            return @parsed_route_error_yml
        end

        # @return hash
        public
        def get_public
            return @parsed_public_yml
        end

        # @return hash
        public
        def get_logger
            return @parsed_logger_yml
        end

        # @param string field
        # @return bool
        public
        def has_error_route?(field)
            # not found route_error.yml just return false
            # check if the field exists
            if !@parsed_route_error_yml.is_a?(Hash) || !@parsed_route_error_yml[field].is_a?(Hash)
                return false
            end

            return @parsed_route_error_yml[field][FIELD_ROUTE_HANDLER].is_a?(String)
        end

        # @return string
        public
        def get_template_file_extension
            return @template_file_extension
        end

        # @return string
        public
        def get_layout_file_extension
            return @layout_file_extension
        end

        # initialize preferences
        public
        def init_pref
            @parsed_route_yml         = YamlAccess::get_parsed_route @path_route_yml
            @parsed_route_include_yml = YamlAccess::get_parsed @path_route_include_yml
            @parsed_route_error_yml   = YamlAccess::get_parsed @path_route_error_yml
            @parsed_public_yml        = YamlAccess::get_parsed @path_public_yml
            @parsed_logger_yml        = YamlAccess::get_parsed @path_logger_yml

            # check if found available route
            if @parsed_route_yml.size == 0
                raise PreferenceError, PreferenceError::MSG_EMPTY_YAML% @path_route_yml
            end

            @template_file_extension = DEFAULT_OPTION_TEMPLATE_FILE_EXT
            @layout_file_extension   = DEFAULT_OPTION_LAYOUT_FILE_EXT
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
