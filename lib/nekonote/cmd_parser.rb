module Nekonote
    class CmdParser
        # @param array argv
        public
        def initialize(argv)
            @argv = argv
        end

        # @return bool
        public
        def version_option?
            return @argv.index('-v') || @argv.index('--version')
        end

        # @return bool
        public
        def help_option?
            return @argv.index('-h') || @argv.index('--help')
        end

        # @return bool
        public
        def root_option?
            return @argv.index '--root'
        end

        # @return nil|mixed
        public
        def get_op_val_root
            index = @argv.index '--root'
            return nil if index == nil
            return @argv[index+1]
        end

        # @return cmd, subcmd, val
        public
        def parse_un_options
            argv = @argv.clone

            # delete options
            index = argv.index '--root'
            if index != nil
                argv.delete_at(index+1) if argv[index+1] != nil
                argv.delete_at index
            end

            # untaint
            argv.map! do |v|
                v.intern.to_s if v.is_a? String
            end

            return *argv
        end
    end
end
