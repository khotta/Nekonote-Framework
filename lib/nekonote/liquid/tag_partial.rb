module Nekonote
    class TagPartial < Liquid::Tag
        def initialize(tag_name, val, parse_context)
            super
            @filepath = val.strip
        end

        def render(context)
            # get assign list from Liquid::Context
            assigns = {}
            context.environments[0].each_pair do |k, v|
                assigns[k] = v
            end

            # absolute path to the partial template
            filepath = View.get_template_path(@filepath)

            # read data and parse it and render it
            data = ''
            begin
                liquid = Liquid::Template.parse IO.read(filepath)
                data   =  liquid.render assigns
            rescue => e
                # ignore this exception
            end

            return data
        end
    end
end
