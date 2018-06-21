# protected methods for conclete handlers
module Nekonote
    class Handler
        module ProtectedMethods
            # assign variables into tempate and layout
            # @param hash list
            # @throw ::Nekonote::Error
            protected
            def __assign(list)
                @view.assign_variables list
            end

            # @param type string|symbol
            protected
            def __set_content_type(type)
                @view.set_content_type type
            end

            # @param string|symbol subject
            # @param mixed value
            protected
            def __set_header(subject, value)
                @view.set_header(subject, value)
            end

            # @param hash headers
            protected
            def __set_headers(headers)
                raise HandlerError, HandlerError::MSG_WRONG_TYPE%[headers.class, 'Hash'] if !headers.is_a?(Hash)
                headers.each_pair do |key, val|
                    @view.set_header(key, val)
                end
            end

            # @param string|symbol subject
            # @param mixed value
            # @param string delimiter
            protected
            def __add_header(subject, value, delimiter = '; ')
                @view.add_header subject, value, delimiter
            end

            # @param int code
            protected
            def __set_code(code)
                @view.set_code code
            end

            # @param string body
            protected
            def __set_body(body)
                @view.set_body body
            end

            # @param string body
            protected
            def __add_body(body)
                @view.add_body body
            end

            # @param hash body
            protected
            def __set_json_body(body)
                raise HandlerError, HandlerError::MSG_WRONG_TYPE%[body.class, 'Hash'] if !body.is_a?(Hash)
                require 'json' if !defined? JSON
                __set_body JSON.pretty_generate(body)
            end

            # Get values in a specified field(s).
            # @param string|synbol fields you can set plual arguments like field1, field2, field3, ...
            # @return mixed|nil in the case of that missing specified key or missing fields will return nil
            protected
            def __setting_get(*fields)
                return Nekonote::Setting.get fields
            end

            # @return array
            protected
            def __setting_keys
                return Nekonote::Setting.keys
            end

            # Get values in a specified field
            # @param string|synbol|nil field
            # @return mixed|nil in the case of that missing specified key or missing fields will return nil
            protected
            def __env_get(field = nil)
                return Nekonote::Env.get field
            end

            # @return array
            protected
            def __env_keys
                return Nekonote::Env.keys
            end

            # @param string path
            protected
            def __set_template(path)
                @view.set_template path
            end

            # @param string path
            protected
            def __set_layout(path)
                @view.set_layout path
            end

            # @param string dest
            # @param int code
            protected
            def __redirect(dest, code=302)
                # validation for types
                raise HandlerError, HandlerError::MSG_WRONG_TYPE%[dest.class, 'String'] if !dest.is_a?(String)
                if !code.is_a?(Fixnum)
                    begin
                    code = code.to_i
                    rescue
                        raise HandlerError, HandlerError::MSG_WRONG_TYPE%[code.class, 'Fixnum or convertible types into Fixnum']
                    end
                end

                # set redirect information
                __set_code code
                __set_header 'Location', dest
                @view.is_redirect = true
            end
        end
    end
end
