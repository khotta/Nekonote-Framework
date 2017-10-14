module Nekonote
    @@from_cli = true

    class Cli
        STRING_RELOADABLE_PREFS = %('setting/', 'logger.yml')
        STRING_CAT_AND_MOUSE    = '      . . . - - - - - - /=^x^)=/      - - ~~(=**)='
        SPACE                   = '    '

        # @param string cmd
        # @param string subcmd
        # @param string val
        # @param hash options
        public
        def initialize(cmd, subcmd=nil, val=nil, options=nil)
            path_structure = File.expand_path(File.dirname(__FILE__)).split '/' 
            path_structure.pop
            path_structure.pop
            @path_structure =%(#{path_structure.join('/')}/data/structure)

            Cli.usage if !cmd.is_a? String
            subcmd  ||= ''
            val     ||= ''
            options ||= {}

            # set-up properties
            root = options[:root]
            root ||= './'
            root += '/' if !root.end_with? '/'
            @root = root

            @cmd     = cmd.intern
            @val     = val.to_s
            @options = options

            if subcmd == ''
                @subcmd = subcmd
            else
                @subcmd = subcmd.intern
            end
        end

        # execute task
        public
        def exec
            case @cmd
            when :new
                # generate something
                case @subcmd
                when :app, :application
                    generate_structure @val

                when :env
                    Nekonote.set_root @root
                    generate_env @val

                when :handler
                    Nekonote.set_root @root
                    generate_handler @val

                when :template, :tpl
                    Nekonote.set_root @root
                    generate_template @val

                when :layout
                    Nekonote.set_root @root
                    generate_layout @val

                when ''
                    # show usage
                    Nekonote::Cli.usage_new

                else
                    raise CLIError, CLIError::MSG_UNKNOWN_AFTER_NEW% @subcmd
                end

            when :server, :s
                # control server
                case @subcmd
                when :start, :st
                    Nekonote.set_root @root
                    start_server

                when :status, :stop, :halt, :restart, :phased_restart
                    Nekonote.set_root @root
                    ctl_server @subcmd

                when :config, :conf
                    Nekonote.set_root @root
                    disp_server_config

                when ''
                    # show usage
                    Nekonote::Cli.usage_server

                else
                    raise CLIError, CLIError::MSG_UNKNOWN_AFTER_SERVER% @subcmd
                end

            when :reload_pref, :rp
                # reload preferences
                Nekonote.set_root @root
                reload_preference

            when :page_cache_clear, :pcc
                # page caches clear
                Nekonote.set_root @root
                page_cache_clear

            when :env
                # disp env
                disp_env

            when :info
                # disp information
                disp_info

            else
                # wrong sub command
                raise CLIError, CLIError::MSG_UNKNOWN_SUB_COMMAND% @cmd
            end

            exit 0
        end

        private
        def start_server
            begin
                puts %(Environment: #{Nekonote.get_env})
                ctl_server :start

            rescue SystemExit
                exit 0

            rescue Exception => e
                CLIError.warning CLIError::MSG_FAILED_START_SERVER
                raise e
            end
        end

        # @param cmd symbol
        private
        def ctl_server(cmd)
            # selectable only puma so far
            (::Nekonote::Puma.new Nekonote.get_root, Nekonote.get_env).ctl_server cmd
        end

        # make temp file to reload preferences
        private
        def reload_preference
            Util::Filer::safe_make_empty_file(Nekonote.get_root_path + Preference::FILE_NAME_FOR_RELOAD)
            disp_success_message %(Now ready for reloading -> #{STRING_RELOADABLE_PREFS})
        end

        private
        def page_cache_clear
            if PageCache.instance.cache_clear
                disp_success_message 'Page cache files was removed.'
            else
                msg = 'No page cache file found. Nothing to do.'
                puts msg
            end
        end

        # @param string env_name
        private
        def generate_handler(path)
            stack        = get_absolute_path_list path, 'handler'
            handler_path = stack.pop
            handler_name = File.basename handler_path
            handler_path += '.rb'
            gen_dir_list = stack

            # check whether the handler exists?
            if File.exists? handler_path
                raise CLIError, CLIError::MSG_ALREADY_EXISTS_HANDLER% handler_path
            end

            # get handler class name
            handler_class_name = ''
            handler_name.split('_').each do |word|
                next if word.empty?
                handler_class_name += word.slice!(0).upcase + word
            end
            if handler_class_name == ''
                raise CLIError, CLIError::MSG_INVALID_HANDLER_NAME% path
            end
            handler_class_name += 'Handler'

            # make directories if necessery
            generate_directory gen_dir_list
            puts '' if gen_dir_list.size > 0

            # make handler class
            content = <<EOS
class #{handler_class_name} < BaseHandler
    def index
    end
end
EOS

            begin
                File.open(handler_path, 'a+') do |f|
                    f.print content
                end
            rescue => e
                raise CLIError, CLIError::MSG_FAILED_CREATE_HANDLER% e.message
            end
            disp_success_message %(Created a new Handler '#{handler_class_name}',  '#{handler_path}')

            disp_note <<EOS
In order to use the created Handler, there is a need to configure routes as:

e.g.
#{handler_class_name}:
   path: /#{handler_name}
   execute: index
EOS
        end

        # @param string path
        private
        def generate_template(path)
            stack         = get_absolute_path_list path, 'static/template'
            template_path = stack.pop + '.tpl'
            gen_dir_list  = stack

            path = path.sub /\/$/, '' if path.end_with? '/'

            # check whether the template exists?
            if File.exists? template_path
                raise CLIError, CLIError::MSG_ALREADY_EXISTS_TEMPLATE% template_path
            end

            # make directories if necessery
            generate_directory gen_dir_list
            puts '' if gen_dir_list.size > 0

            # make template
            content = %()

            begin
                File.open(template_path, 'a+') do |f|
                    f.print content
                end
            rescue => e
                raise CLIError, CLIError::MSG_FAILED_CREATE_TEMPLATE% e.message
            end
            disp_success_message %(Created a new template '#{template_path}')

            disp_note <<EOS
In order to use the template file you created, you need to set 'template' directive in your route as:

e.g.
ExampleHandler
   path: /example
   execute: index
   template: #{path}
EOS
        end

        # @param string path
        private
        def generate_layout(path)
            stack        = get_absolute_path_list path, 'static/layout'
            layout_path  = stack.pop + '.tpl'
            gen_dir_list = stack

            path = path.sub /\/$/, '' if path.end_with? '/'

            # check whether the layout exists?
            if File.exists? layout_path
                raise CLIError, CLIError::MSG_ALREADY_EXISTS_LAYOUT% layout_path
            end

            # make directories if necessery
            generate_directory gen_dir_list
            puts '' if gen_dir_list.size > 0

            # make layout
            content = %()

            begin
                File.open(layout_path, 'a+') do |f|
                    f.print content
                end
            rescue => e
                raise CLIError, CLIError::MSG_FAILED_CREATE_LAYOUT% e.message
            end
            disp_success_message %(Created a new layout '#{layout_path}')

            disp_note <<EOS
In order to use the layout file you created, you need to set 'layout' directive in your route as:

e.g.
ExampleHandler
   path: /example
   execute: index
   layout: #{path}
EOS
        end

        # @param string env
        private
        def generate_env(env)
            stack = get_absolute_path_list env, 'preference'
            if stack.size != 1
                raise CLIError, CLIError::MSG_INVALID_ENV_NAME% env
            end
            env_path = stack.pop

            # check whether the envinronment exists or not
            if File.exists? env_path
                raise CLIError, CLIError::MSG_ALREADY_EXISTS_ENV% env_path
            end

            # get base path
            base_path = get_base_path 'preference/development'

            # copy
            begin
                FileUtils.cp_r base_path, env_path
            rescue => e
                msg = 'Failed to create a new envinroment by the following reason.' + $/
                msg += e.message
                raise CLIError, msg
            end

            # replace
            replace_puma_config Nekonote.get_root, env

            # display message
            disp_success_message %(Created a new environment '#{env}' on the application #{Nekonote.get_root})
            disp_note <<EOS
In order to use the environment you created, you need to set '#{env}' to a shell variable called NEKONOTE_ENV.
EOS
        end

        # @param string app_name
        private
        def generate_structure(app_name)
            # validation
            option = {:allow_first_slash => true}
            check_new_name app_name, option

            base_dir = File.expand_path File.dirname(app_name)
            name     = File.basename app_name

            # is it possible to make application structure in base_dir?
            if !Util::Filer.available_dir? base_dir
                raise CLIError, CLIError::MSG_PERMIT_MAKE_DIR% base_dir
            end

            # application root
            app_root = base_dir + '/' + name

            # check whether there is something or not?
            if File.exist? app_root
                raise CLIError, CLIError::MSG_ALREADY_EXISTS_APP% app_root
            end

            # check whether there is the directory for generating structure
            if !File.directory? @path_structure
                raise CLIError, CLIError::MSG_MISSING_STRUCTURE_DIR% @path_structure
            end

            # generate apps root dir
            Dir.mkdir app_root

            # generate files and directories
            cp_from  = @path_structure + '/'
            files = ['Gemfile', 'config.ru']
            dirs  = ['handler', 'lib', 'preference', 'public', 'static', 'tmp']
            free_dirs_to_make = ['cache', 'log']

            # copy files
            files.each do |name|
                file_path = "#{app_root}/#{name}"
                FileUtils.cp cp_from + name, file_path
                CE.once.fg(:green).tx(:bold)
                puts SPACE + "* Created a file -> #{file_path}"
            end

            # copy directories
            dirs.each do |name|
                dir_path = "#{app_root}/#{name}"
                FileUtils.cp_r cp_from + name, dir_path
                CE.once.fg(:yellow).tx(:bold)
                puts SPACE + "* Created a directory -> #{dir_path}"

                files = Dir[dir_path + '/**/*']
                files.each do |path|
                    if File.directory? path
                        CE.once.fg :yellow
                        puts SPACE + "  Created a directory -> #{path}"
                    else
                        CE.once.fg :green
                        puts SPACE + "  Created a file -> #{path}"
                    end
                end
            end

            # replace
            env = 'development'
            replace_puma_config app_root, env
            replace_gemfile app_root, Nekonote::VERSION

            # change the permissions
            puts ''
            free_dirs_to_make.each do |name|
                file_path = "#{app_root}/#{name}"
                Dir.mkdir file_path
                FileUtils.chmod 0777, file_path
                CE.once.fg(:yellow).tx(:bold)
                puts SPACE + "* Created a directory (0777) -> #{file_path}"

                keep_file = "#{file_path}/.gitkeep"
                File.open keep_file, 'w' do end
                CE.once.fg :green
                puts SPACE + "  Created a file -> #{keep_file}"
            end

            # display success messages
            puts ''
            disp_success_message "Generated a new application -> #{app_root}"

            # display the note
            msg = <<EOS
The generated application will be published on TCP port 2002 after starting the web server by
'NEKONOTE_ENV=#{env} nekonote server start --root #{app_root}' or 'cd #{app_root} && NEKONOTE_ENV=#{env} nekonote server start'
The web server will accpet accessing from any IP addresses.
EOS
            disp_note msg, '1'

            msg = <<EOS
It's possible to configure preferences for the web server by the configuration file located in the structure you just generated.
You can display the path to the configuration file by typing 'NEKONOTE_ENV=#{env} nekonote server conf --root #{app_root}'
EOS
            disp_note msg, '2'

            msg = <<EOS
The web server is deamonized by default. You can see the help for controlling the web server just typing 'nekonote server'.
In order to start the web server, Please typing 'NEKONOTE_ENV=#{env} nekonote server start --root #{app_root}'
As of now you have just one environment named '#{env}'.
When the shell variable NEKONOTE_ENV is set on your shell, you don't need to place NEKONOTE_ENV=#{env} to the beginning of 'nekonote' command.
EOS
            disp_note msg, '3'

            msg = <<EOS
Have you had installed the dependent libraries?
If you didn't yet, please install them by 'Bundler' like following:

* bundle install
    Installing dependencies into all system gems.

* bundle install --path vendor/bundle
    Installing into a specific directory in your application structure.
EOS
            disp_note msg, '4'

            puts STRING_CAT_AND_MOUSE + $/ + $/
        end

        # @param string app_root
        # @param string env
        private
        def replace_puma_config(app_root, env)
            after = ''
            config_path = "#{app_root}/preference/#{env}/server/puma.rb"
            File.open(config_path, 'r+') do |f|
                after = f.read.sub 'REPLACE_ME_TO_APP_ROOT', app_root
                f.truncate 0
            end
            File.open(config_path, 'r+') do |f|
                f.print after
            end
        end

        # @param string app_root
        # @param string env
        private
        def replace_gemfile(app_root, version)
            after = ''
            gemfile_path = "#{app_root}/Gemfile"
            File.open(gemfile_path, 'r+') do |f|
                after = f.read.sub 'REPLACE_ME_TO_NEKONOTE_VERSION', version
                f.truncate 0
            end
            File.open(gemfile_path, 'r+') do |f|
                f.print after
            end
        end

        # @param string path
        # @param string dest
        # @return array
        private
        def get_absolute_path_list(path, dest)
            # validation
            check_new_name path

            # check if there is the directory to generate new handler
            base_path = Nekonote.get_root_path + dest
            if !File.directory? base_path
                raise CLIError, CLIError::MSG_MISSING_DEST_PATH% base_path
            end
            base_path += '/'

            # perse handler name and its path
            stack = []
            dir = base_path
            path.split('/').each do |name|
                stack << dir + name
                dir += name + '/'
            end

            if stack.size == 0
                raise CLIError, CLIError::MSG_INVALID_NEW_NAME% path
            end

            return stack
        end

        # @param string path path to base that without starting with slash
        private
        def get_base_path(path = '')
            # check there is the directory for generating structure
            if !File.directory? @path_structure
                raise CLIError, CLIError::MSG_MISSING_STRUCTURE_DIR% @path_structure
            end

            # check there is the base-directory for generating new env
            base_path = @path_structure + '/' + path
            if !File.directory? base_path
                raise CLIError, CLIError::MSG_MISSING_STRUCTURE_DIR% base_path
            end

            return base_path
        end

        # @param array stack
        private
        def generate_directory(stack)
            stack.each do |dir|
                if File.directory? dir
                    # nothing to do
                elsif File.exist? dir
                    raise CLIError, CLIError::MSG_FAILED_GEN_DIR_BY_FILE% dir
                else
                    Dir.mkdir dir
                    CE.once.fg :yellow
                    puts SPACE + '* Created a directory -> ' + dir
                end
            end
        end

        # @param string name
        # @param hash option
        # @throw CLIError
        # @return void
        private
        def check_new_name(name, option = {})
            if name == ''
                raise CLIError, CLIError::MSG_MISSING_NEW_PATH
            end

            option = {} if !option.is_a? Hash
            if name =~ /^[^0-9a-zA-Z]/
                if !option[:allow_first_slash]
                    raise CLIError, CLIError::MSG_INVALID_NEW_NAME% name
                end
            end
        end

        # @param string msg
        private
        def disp_success_message(msg)
            CE.times(2).fg :cyan
            puts SPACE + 'Success!'
            puts SPACE + '  ' + msg + $/
        end

        # @param string msg
        # @param string|nil
        private
        def disp_note(msg, num = nil)
            puts ''
            CE.once.fg(:white).tx(:bold)
            if num.is_a? String
                header = %(Note #{num}:)
            else
                header = %(Note:)
            end
            puts SPACE + header

            CE.fg(:white)
            msg.lines do |line|
                puts SPACE + '  ' + line
            end
            CE.off
            puts ''
        end

        # disp information
        private
        def disp_info
            env = Nekonote.has_valid_env? ? Nekonote.get_env : 'Environment is not set. Please set NEKONOTE_ENV.'
            puts %(Version: #{VERSION})
            puts %(Current Environment: #{env})
            puts $/ + STRING_CAT_AND_MOUSE + $/ + $/
        end

        # disp current environment
        private
        def disp_env
            begin
                env = Nekonote.get_env
            rescue Nekonote::Error
                env = nil
            end

            if env != nil
                puts env
            else
                puts 'Missing Environment:'
                disp_note <<EOS
You haven't set any environment now!
You need to set some environment for your application by declaring a shell variable called NEKONOTE_ENV.
EOS
            end
        end

        private
        def disp_server_config
            puma = ::Nekonote::Puma.new Nekonote.get_root, Nekonote.get_env
            puts puma.get_config_path
        end

        # ----------------
        # class methods
        # ----------------
        # output the version
        def self.version(status = 0)
            puts VERSION
            exit status if status != nil
        end

        # out put the usage for nekonote new
        def self.usage_new
            puts <<-EOS
[Usage]
  nekonote new <sub_command> <value>

[Sub Commands]
  application, app <application_name>  Generates a new nekonote application structure.
  env <environment_name>               Create a new environment for an existing application structure.
  handler <handler_name>               Create a new handler for an existing application structure. You may pass a relative path.
  template, tpl <template_name>        Create a new template file for an existing application structure. You may pass a relative path.
  layout <layout_name>                 Create a new layout file for an existing application structure. You may pass a relative path.
EOS
        end

        # out put the usage for nekonote server
        def self.usage_server
            puts <<-EOS
[Usage]
  nekonote server, s <sub_command>

[Sub Commands]
  start, st         Starts the web server.
  stop              Stop the web server.
  halt              Halts the web server.
  restart           Restarts the web server.
  phased_restart    Reqests phased restart to puma web server.
  status            Displays status of the web server.
  config, conf      Displays a path to the configuration file.
EOS
        end

        # output the usage
        def self.usage
            puts <<-EOS
[Usage]
  nekonote [options] <command> [<sub_command> [<value>]]

[Commands]
  new                      Creates something. You can see the details by just typing 'nekonote new'.
  server, s                Controls the web server. You can see the details by just typing 'nekonote server'.
  reload_pref, rp          Reloads preferences without restarting or reloading server. Only #{STRING_RELOADABLE_PREFS} are reloadable.
  page_cache_clear, pcc    Removes page cache files in the 'cache' directory.
  env                      Displays the current application environment.
  info                     Displays some information.

[Options]
  -v, --version    Shows the version of your Nekonote Framework.
  -h, --help       Shows this information.
  --root <path>    Declares an application root. The default is your current directory.
            EOS

            exit 0
        end
    end
end
