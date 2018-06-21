module Nekonote
    # define original liquid tag
    ::Liquid::Template.register_tag 'env_get', TagEnvGet
    ::Liquid::Template.register_tag 'setting_get', TagSettingGet

    class View
        NO_USING_NAME       = 'none'
        DEFAULT_LAYOUT_NAME = 'default'
        PATH_TO_TEMPLATE    = 'template'
        PATH_TO_LAYOUT      = 'template/layout'

        # accessor
        attr_accessor :is_redirect
        attr_reader   :is_error_route,
                      :info_path,
                      :info_exec_method,
                      :info_allow_methods,
                      :info_params,
                      :info_content_type,
                      :info_template,
                      :info_layout,
                      :info_page_cache_time

        # @return array
        def self.get_default_error_response
            return [
                500,
                {
                },
                []
            ]
        end

        # @param hash info
        # @param string handler_name
        # @param nil|string error_field_name
        def initialize(info, handler_name, error_field_name = nil)
            register_info_properies info

            # initialize response
            init_for_response

            # check error route or not?
            if error_field_name.is_a? String
                @is_error_route = true
                # set default response code for error (users can customize it on concrete handlers).
                set_code get_error_response_code(error_field_name)
            else
                @is_error_route = false
            end

            # initialize template and layout
            init_template handler_name
            init_layout

            # assign extra fields into templates
            assign_custom_fields info
        end

        # Initialize stored information about response
        public
        def init_for_response
            @response = ::Rack::Response.new
            set_content_type @info_content_type

            # initialize the properties
            @is_body_set = false
            @is_redirect = false
        end

        # Is page cache enabled for this route.
        # @return bool
        public
        def enable_page_cache?
            return @info_page_cache_time.is_a? Integer
        end

        # Need to create page cache?
        # @param string uri
        # @return bool
        public
        def need_create_page_cache?(uri)
            return enable_page_cache? && !PageCache.instance.has_available_cache?(uri, @info_page_cache_time)
        end

        # Is it Allowed to gets response data from page cache for givevn uri?
        # @param string uri
        # @return bool
        public
        def can_get_from_page_cache?(uri)
            return enable_page_cache? && PageCache.instance.has_available_cache?(uri, @info_page_cache_time)
        end

        # Makes page cache file
        # @param string uri
        public
        def create_page_cache(uri)
            PageCache.instance.make_cache(
                uri,
                @response.status,
                @response.header,
                @response.body
            )
        end

        # @return array
        public
        def get_response_data
            return @response.finish
        end

        # Gets response data for given uri from page cache
        # @param string uri
        public
        def get_response_data_from_page_cache(uri)
            return PageCache.instance.get_page_cache uri
        end

        # @return string
        public
        def set_body_with_tpl
            # if nil is given for layout and/or template, No template and/or layout will be used
            if @template_path != nil && !Util::Filer.available_file?(@template_path)
                raise ViewError, ViewError::MSG_MISSING_TEMPLATE_FILE% @template_path
            end

            if @layout_path != nil && !Util::Filer.available_file?(@layout_path)
                raise ViewError, ViewError::MSG_MISSING_LAYOUT_FILE% @layout_path
            end

            @response.write get_parsed(@template_path, @layout_path)
        end

        # @param string|symbol subject
        # @param mixed value
        public
        def set_header(subject, value)
            subject = subject.to_s if subject.is_a?(Symbol)
            raise ViewError, ViewError::MSG_WRONG_TYPE%[subject.class, 'String or Symbol'] if !subject.is_a?(String)
            @response[subject] = value
        end

        # @param string type
        public
        def set_content_type(type)
            @response['Content-Type'] = get_content_type type
        end

        # @param string|symbol subject
        # @param mixed value
        # @param string delimiter
        public
        def add_header(subject, value, delimiter)
            subject = subject.to_s if subject.is_a?(Symbol)
            raise ViewError, ViewError::MSG_WRONG_TYPE%[subject.class, 'String or Symbol'] if !subject.is_a?(String)
            raise ViewError, ViewError::MSG_WRONG_TYPE%[delimiter.class, 'String'] if !delimiter.is_a?(String)

            if @response.header.has_key? subject
                @response[subject] = "#{@response[subject]}#{delimiter}#{value}"
            else
                set_header subject, value
            end
        end

        # @param int code
        public
        def set_code(code)
            begin
                code = code.to_i if !code.is_a?(Fixnum)
            rescue
                raise ViewError, ViewError::MSG_WRONG_TYPE%[code.class, 'Fixnum or convertible types into Fixnum']
            end
           @response.status = code
        end

        # @param string body
        public
        def set_body(body)
            if !body.is_a?(String)
                begin
                    body = body.to_s
                rescue
                    raise ViewError, ViewError::MSG_WRONG_TYPE%[body.class, 'String or convertible types into Fixnum']
                end
            end
            @response.body = []
            @response.write body
            @is_body_set = true
        end

        # @param string body
        public
        def add_body(body)
            if !body.is_a?(String)
                begin
                    body = body.to_s
                rescue
                    raise ViewError, ViewError::MSG_WRONG_TYPE%[body.class, 'String or convertible types into String']
                end
            end
            @response.write body
            @is_body_set = true
        end

        # is set something for response body?
        public
        def is_body_set?
            return @is_body_set
        end

        # assign mapping into teplate and/or layout
        # when already exst mapping it would be merged
        # @param hash list
        # @throw ::Nekonote::Error
        public
        def assign_variables(list)
            if !list.is_a? Hash
                raise ViewError, ViewError::MSG_FAILED_TO_ASSIGN
            end

            # convert symbol key to string key
            list_cnv = {}
            list.map {|pair| list_cnv[pair[0].to_s] = pair[1] }

            if defined?(@mapping) && @mapping.is_a?(Hash)
                @mapping.merge! list_cnv
            else
                @mapping = list_cnv
            end
        end

        # assign custom fields into teplate and/or layout
        # @param bool is_error_route
        public
        def assign_custom_fields(info)
            fields = Preference.get_custom_fields info, @is_error_route
            if fields.is_a?(Hash)
                assign_variables fields
            end
        end

        # Need reload after method was called and commented out it because view object will alive
        # @param string path relative path from app root to template file
        public
        def set_template(path)
            @info_template = path
            init_template
        end

        # Need reload after method was called and commented out it because view object will alive
        # @param string path relative path from app root to layout file
        public
        def set_layout(path)
            @info_layout = path
            init_layout
        end

        # @param hash info
        private
        def register_info_properies(info)
            @info_path            = info[Preference::FIELD_ROUTE_PATH]
            @info_exec_method     = info[Preference::FIELD_ROUTE_EXEC_METHOD]
            @info_allow_methods   = info[Preference::FIELD_ROUTE_ALLOW_METHODS]
            @info_params          = info[Preference::FIELD_ROUTE_PARAMS]
            @info_content_type    = info[Preference::FIELD_ROUTE_CONTENT_TYPE]
            @info_template        = info[Preference::FIELD_ROUTE_TEMPLATE]
            @info_layout          = info[Preference::FIELD_ROUTE_LAYOUT]
            @info_page_cache_time = info[Preference::FIELD_ROUTE_PAGE_CACHE_TIME]
        end

        # initialize the properties
        private
        def init_property
            @is_body_set = false
            @is_redirect = false
        end

        # initialize conf about template by @info_template
        # @param string|nil handler_name
        private
        def init_template(handler_name = nil)
            if @info_template.is_a? String
                # check exists later
                @template_path = get_template_path @info_template
            elsif @info_template == nil && handler_name.is_a?(String)
                # try to set a default template
                @template_path = get_default_template_path handler_name
            else
                # no use template
                @template_path = nil
            end
        end

        # initialize conf about layout by @info_layout
        private
        def init_layout
            if @info_layout.is_a? String
                # check exists later
                @layout_path = get_layout_path @info_layout
            elsif @info_layout == nil
                # try to set a default layout
                @layout_path = get_layout_path DEFAULT_LAYOUT_NAME
                if !Util::Filer.available_file? @layout_path
                    @layout_path = nil
                end
            else
                # no use layout
                @layout_path = nil
            end
        end

        # @param string template relative path to template file
        # @return string absolute path
        private
        def get_template_path(template)
            return Nekonote.get_root_path + PATH_TO_TEMPLATE + '/' + template + '.tpl'
        end

        # @param string layout relative path to layout file
        # @return string absolute path
        private
        def get_layout_path(layout)
            return Nekonote.get_root_path + PATH_TO_LAYOUT + '/' + layout + '.tpl'
        end

        # Returns template path for the default when it was found and available
        # @param string|nil
        private
        def get_default_template_path(handler_name)
            return nil if !handler_name.is_a? String

            # get default template path when no template specified
            begin
                template = handler_name.sub(/Handler$/, '').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
            rescue
                template = nil
            end

            # return nil if invalid template name
            return nil if (template.nil? || template == '')

            # get absolute path
            template_path = get_template_path template

            # set if available
            if Util::Filer.available_file? template_path
                template_path = template_path
            else
                template_path = nil
            end

            return template_path
        end

        # @param string type
        # @return string
        private
        def get_content_type(type)
            type = type.intern if type.is_a?(String)

            content_type = 'text/plain'
            if type == nil
                content_type = 'text/html'
            elsif type == :html
                content_type = 'text/html'
            elsif type == :json
                content_type = 'application/json'
            elsif type == :xml
                content_type = 'application/xml'
            elsif type == :plain
                content_type = 'text/plain'
            end
            return content_type
        end

        # @param string field
        private
        def get_error_response_code(field)
            case field
            when Preference::FIELD_ROUTE_ERR_MISSING_ROUTE
                return 404
            when Preference::FIELD_ROUTE_ERR_WRONG_METHOD
                return 405
            when Preference::FIELD_ROUTE_ERR_FATAL
                return 500
            when Preference::FIELD_ROUTE_ERR_NOT_FOUND
                return 404
            else
                raise PreferenceError, PreferenceError::MSG_UNDEFINED_FIELD% field
            end
        end

        # @param string|nil template_path
        # @param string|nil layout_path
        # @return string
        private
        def get_parsed(template_path = nil, layout_path = nil)
            data = ''
            liq_tpl_template = nil
            liq_tpl_layout   = nil
            begin
                if template_path.is_a? String
                    liq_tpl_template = Liquid::Template.parse IO.read(template_path)
                end

                if layout_path.is_a? String
                    liq_tpl_layout = Liquid::Template.parse IO.read(layout_path)
                end

                # parse and render template
                if liq_tpl_template.is_a? Liquid::Template
                    content = liq_tpl_template.render @mapping
                else
                    content = nil
                end

                # parse and render layout
                if liq_tpl_layout.is_a? Liquid::Template
                    if content != nil
                        # assgin tempalte for layout
                        mapping = {
                            'content' => content
                        }
                        # and put it to @mapping
                        @mapping.merge! mapping
                    end
                    data = liq_tpl_layout.render @mapping

                else
                    # if template data is available set it to data
                    data = content if content != nil
                end

            rescue => e
                raise ViewError, e.message
            end

            return data
        end
    end
end
