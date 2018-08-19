module Nekonote
    # define original liquid tag
    ::Liquid::Template.register_tag 'env_get', TagEnvGet
    ::Liquid::Template.register_tag 'setting_get', TagSettingGet
    ::Liquid::Template.register_tag 'partial', TagPartial

    class View
        PATH_TO_TEMPLATE = 'template'
        PATH_TO_LAYOUT   = 'template/layout'
        PATH_TO_PARTIAL  = 'template/partial'

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

        # Returns default response for error
        # @return array
        def self.get_default_error_response
            return [
                500,
                {
                },
                []
            ]
        end

        # @param string filepath
        # @return string
        def self.get_template_path(filepath)
            return Nekonote.get_root + '/' + self::PATH_TO_PARTIAL + '/' + filepath + '.tpl'
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

            elsif @layout_path != nil && !Util::Filer.available_file?(@layout_path)
                raise ViewError, ViewError::MSG_MISSING_LAYOUT_FILE% @layout_path
            end

            @response.write get_parsed
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

            if defined?(@assign_list) && @assign_list.is_a?(Hash)
                @assign_list.merge! list_cnv
            else
                @assign_list = list_cnv
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
                # checking whether to exist or not is later 
                @template_path = get_template_path @info_template
            else
                # no use template
                @template_path = nil
            end
        end

        # initialize conf about layout by @info_layout
        private
        def init_layout
            if @info_layout.is_a? String
                # checking whether to exist or not is later
                @layout_path = get_layout_path @info_layout
            else
                # no use layout
                @layout_path = nil
            end
        end

        # @param string template relative path to template file
        # @return string absolute path
        private
        def get_template_path(template)
            ext = Preference.instance.get_template_file_extension
            return "#{Nekonote.get_root_path}#{PATH_TO_TEMPLATE}/#{template}.#{ext}"
        end

        # @param string layout relative path to layout file
        # @return string absolute path
        private
        def get_layout_path(layout)
            ext = Preference.instance.get_layout_file_extension
            return "#{Nekonote.get_root_path}#{PATH_TO_LAYOUT}/#{layout}.#{ext}"
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

        # @return string
        private
        def get_parsed
            begin
                # parse data in template file
                template_data = render_data_with_liquid(@template_path, @assign_list)

                # assign it into variable [content] if template was avalable
                if template_data != nil
                    @assign_list['content'] = template_data 
                end

                # parse data in layout file with template data
                layout_data = render_data_with_liquid(@layout_path, @assign_list)

                response_body = ''
                if layout_data != nil
                    # just layout or with template
                    response_body = layout_data
                elsif template_data != nil
                    # just template
                    response_body = template_data
                end
            rescue => e
                raise ViewError, e.message
            end

            return response_body
        end

        # @param string filepath path to file
        # @param hash assigns variables to assign
        # @return Liquid::Template|nil
        # @throw Exception
        def render_data_with_liquid(filepath, assigns)
            return nil if !filepath.is_a? String
            liquid = Liquid::Template.parse IO.read(filepath)
            return liquid.render assigns
        end
    end
end
