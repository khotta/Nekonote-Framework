module Nekonote
    class TagSettingGet < Liquid::Tag
        def initialize(tag_name, val, parse_context)
            super
            @val = val.strip.split ','
        end

        def render(context)
            return Nekonote::Setting.get @val
        end
    end
end
