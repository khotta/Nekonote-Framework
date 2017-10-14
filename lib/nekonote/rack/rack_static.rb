module Nekonote
    class RackStatic < ::Rack::Static
        def initialize(app, options={})
            if options[:root] == nil
                raise Error, self.class.to_s + ' require key :root'
            end

            super

            # Overwrite property for using Nekonote::RackStaticFile instead of Rack::File.
            # This for handling the error case that file requested was not found.
            @file_server = RackStaticFile.new options[:root]

            # @file_server = Rack::File.new(root)
        end
    end
end
