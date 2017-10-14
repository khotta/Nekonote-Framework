module Nekonote
    module Util
        module Process
            # @param string path
            # @return int|nil
            def get_server_pid(path)
                return nil if !Filer.available_file? path

                pid = nil
                File.open(path, 'r') do |f|
                    pid = f.read
                    pid.rstrip! && pid = pid.to_i if pid.is_a? String
                end

                # There's pid file but actually the process is dead
                if pid != nil && !alive_process?(pid)
                    pid = nil
                end

                return pid
            end

            # Is process of given pid running?
            # @param int pid
            # @return bool
            def alive_process?(pid)
                return false if !pid.is_a? Integer

                begin
                    ::Process.getpgid pid
                    alive = true
                rescue Errno::ESRCH
                    alive = false
                end

                return alive
            end

            module_function :get_server_pid,
                            :alive_process?
        end
    end
end
