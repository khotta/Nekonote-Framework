module Nekonote
    module Util
        module Filer
            # is path file? and is it readable?
            # @param string|io path
            # @return bool
            def available_file?(path)
                return File.file?(path) && File.readable?(path)
            end

            # is path directory? and is it friendly permission?
            # @param string|io path
            # @return bool
            def available_dir?(path)
                evaluation = false
                if File.directory? path
                    stat = File::Stat.new path
                    evaluation = stat.readable? && stat.writable? && stat.executable?
                end
                return evaluation
            end

            # Makes an empty file named the given name if it doesn't exist
            # @param string path
            def safe_make_empty_file(path)
                if File.exist? path
                    File.open(path, 'r') do |f|
                        if !f.read.empty?
                            raise Error, Error::MSG_EMPTY_FILE_NOT_EMPTY% path
                        end
                    end
                end

                # make an empty file
                File.open(path, 'a') do |f|
                end
            end

            # @param string path
            def safe_delete_empty_file(path)
                if File.exist? path
                    File.open(path, 'r') do |f|
                        if !f.read.empty?
                            raise Error, Error::MSG_EMPTY_FILE_NOT_EMPTY% path
                        end
                    end
                end

                # delete an empty file
                File.delete path
            end

            # delete end of slash if it exists
            # @param string path
            # @return string
            def unslashed(path)
                path.sub! /\/$/, '' if path.end_with? '/'
                return path
            end

            # define them as module function
            module_function :available_file?,
                            :available_dir?,
                            :safe_make_empty_file,
                            :safe_delete_empty_file,
                            :unslashed
        end
    end
end
