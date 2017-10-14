module Nekonote
    class Env
        private_class_method :new
        @rackenv = {}

        # Get values in a specified field
        # @param string|synbol|nil field
        # @return mixed|nil in the case of that missing specified key or missing fields will return nil
        def self.get(field = nil)
            return nil if field == nil

            if !field.is_a? String
                field = field.to_s
            end

            field.strip!
            return '' if field == ''

            return @rackenv[field]
        end

        # Get the whole environments
        # @return hash
        def self.get_all
            return @rackenv
        end

        # @return string
        def self.current
            return Nekonote.get_env
        end

        # @return string
        def self.root
            return Nekonote.get_root
        end

        # @return string
        def self.root_path
            return Nekonote.get_root_path
        end

        # @return array|nil
        def self.keys
            if @rackenv.is_a? Hash
                return @rackenv.keys
            end
            return nil
        end

        # @param hash rackenv
        def self.set_rackenv(rackenv)
            @rackenv = rackenv
        end
    end
end
