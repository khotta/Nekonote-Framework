module Nekonote
    class YamlAccess
        DIR_PREFERENCE = 'preference'

        # @param string path
        # @return hash
        def self.get_parsed(path)
            if !Util::Filer.available_file? path
                return nil
            end

            begin
                contents = YAML.load_file path
                contents = {} if (!contents.is_a? Hash)
                return contents

            rescue Psych::SyntaxError => e
                msg  = PreferenceError::MSG_WRONG_YAML_SYNTAX% path
                msg += $/ + $/ + e.message
                raise PreferenceError, msg
            end
        end

        # Returns the parsed routing information
        # @param string path
        # @return hash
        def self.get_parsed_route(path)
            if !Util::Filer.available_file? path
                return nil
            end

            begin
                ast = YAML.parse_file path

                route_list = []
                ast.root.children.each_with_index do |node, index|
                    cnt = index / 2
                    if node.is_a?(Psych::Nodes::Scalar) && node.value != Preference::FIELD_ROUTING_OPTIONS
                        route_list[cnt] = {Preference::FIELD_ROUTE_HANDLER => node.value}
                    elsif node.is_a? Psych::Nodes::Mapping
                        if route_list[cnt].is_a? Hash
                            route_list[cnt] = route_list[cnt].merge node.to_ruby
                        end
                    end
                end

                parsed = []
                route_list.each do |info|
                    parsed << info if info.is_a?(Hash)
                end

                return parsed

            rescue Psych::SyntaxError => e
                msg  = PreferenceError::MSG_WRONG_YAML_SYNTAX% path
                msg += $/ + $/ + e.message
                raise PreferenceError, msg
            end
        end
    end
end
