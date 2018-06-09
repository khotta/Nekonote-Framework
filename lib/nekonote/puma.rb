module Nekonote
    class Puma
        # @param string app_root
        # @param string env
        def initialize(app_root, env)
            @app_root = app_root
            @env      = env
        end

        # @return string
        public
        def get_config_path
            return get_puma_config_file_path
        end

        # @param cmd symbol
        public
        def ctl_server(cmd)
            # set pumactl command corresponded with nekonote sub command
            case cmd
            when :start
                puma_cmd = 'start'

            when :status
                puma_cmd = 'status'

            when :stop
                puma_cmd = 'stop'

            when :halt
                puma_cmd = 'halt'

            when :restart
                puma_cmd = 'restart'

            when :phased_restart
                puma_cmd = 'phased-restart'
            end

            # make object
            argv = ['-F', get_puma_config_file_path, puma_cmd] 
            stdout_buffer = $stdout.clone
            stderr_buffer = $stderr.clone

            begin
                if cmd == :start
                    change_exec_file_to_puma_bin # if did't change $0 to puma/bin/puma, restart will be failed
                end
                cli = ::Puma::ControlCLI.new argv, STDOUT, STDERR

                # get pid if it exists
                def cli.get_pid_file_path
                    return @pidfile
                end
                pid = Util::Process.get_server_pid cli.get_pid_file_path

                # exit if there's no need to run Puma::ControlCLI
                nothing_to_do = false
                case cmd
                when :start
                    if pid != nil
                        puts %(Already started -> pid #{pid})
                        nothing_to_do = true
                    end

                when :status
                    if pid == nil
                        puts %(Server is stopped)
                    else
                        puts %(Server is running -> pid #{pid})
                    end
                    nothing_to_do = true

                when :stop, :halt
                    if pid == nil
                        puts %(Already stopped)
                        nothing_to_do = true
                    end

                when :restart, :phased_restart
                    if pid == nil
                        # it have not started!
                        ctl_server :start
                        nothing_to_do = true
                    end
                end

                # exit if no need to continue task
                if nothing_to_do
                    $stdout = stdout_buffer
                    $stderr = stderr_buffer
                    exit 0
                end

                # send signal
                # when requested 'start' it will exit here
                cli.run

            ensure
                # it won't called if script exited
                $stdout = stdout_buffer
                $stderr = stderr_buffer
            end
        end

        private
        def change_exec_file_to_puma_bin
            puma_bin_path = "#{::Bundler.bundle_path.to_s}/gems/puma-#{::Puma::Const::VERSION}/bin/puma"

            # is it readable?
            if !Util::Filer.available_file? puma_bin_path
                raise PreferenceError, Error::MSG_MISSING_FILE% puma_bin_path
            end

            $0 = puma_bin_path
        end

        # @return string
        private
        def get_puma_config_file_path
            file_path = "#{@app_root}/preference/#{@env}/server/puma.rb"

            # is it readable?
            if !Util::Filer.available_file? file_path
                raise PreferenceError, Error::MSG_MISSING_FILE% file_path
            end

            return file_path
        end
    end
end
