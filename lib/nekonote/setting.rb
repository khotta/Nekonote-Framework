module Nekonote
    class Setting
        include Singleton
        DIR_SETTING = 'setting'

        # read yaml data from files under setting directory
        def self.init
            path = Nekonote.get_root_path + YamlAccess::DIR_PREFERENCE + '/' + Nekonote.get_env + '/' + DIR_SETTING
            Dir.chdir path

            @setting = {}
            Dir["#{Dir.pwd}/**/*.yml"].each do |file|
                next if File.directory? file
                parsed = YamlAccess::get_parsed file
                if parsed.is_a? Hash
                    @setting.merge! parsed
                end
            end
        end

        # Get all root filed names
        # @return array
        def self.keys
            return @setting.keys
        end

        # Get the whole environments
        # @return hash
        def self.get_all
            return @setting
        end

        # Get values in a specified field(s).
        # @param string|synbol fields you can set plual arguments like field1, field2, field3, ...
        # @return mixed|nil in the case of that missing specified key or missing fields will return nil
        def self.get(*fields)
            if !defined?(@setting) || !@setting.is_a?(Hash)
                return nil
            end

            if fields.count == 1 && fields[0].is_a?(Array)
                fields = fields[0]
            end

            stack = nil
            fields.each do |field|
                field = field.to_s.strip
                if stack.is_a? Hash
                    # get next field
                    stack = stack[field]
                else
                    stack = @setting[field]
                end
            end

            return stack
        end
    end
end
