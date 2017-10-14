module Nekonote
    class TagEnvGet < Liquid::Tag
        def initialize(tag_name, val, parse_context)
            super
            @val = val.strip
        end

        def render(context)
            return Env.get @val
        end
    end
end
