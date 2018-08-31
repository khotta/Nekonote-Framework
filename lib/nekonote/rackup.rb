module Nekonote
    class Rackup
        include Singleton

        def initialize
            begin
                # initialize Logger
                Nekonote.init_logger

                # initialize Setting
                Setting.init
            rescue => e
                Error.abort e
            end
        end

        # @param mixed info
        # @return hash
        def self.get_header_rules_field(info)
            headers = {}
            if info.is_a? Hash
                # just one header
                headers = {info['name'] => info['value']}

            elsif info.is_a? Array
                # plural headers
                headers = {}
                info.each do |pair|
                    headers[pair['name']] = pair['value']
                end
            end
            return headers
        end

        # @param mixed info
        # @param proc get_rule
        # @return hash
        def self.get_header_rules_field_having_target(info, get_rule)
            rules = []
            if info.is_a?(Array)
                # multiple
                stack = []
                info.each do |each_ext|
                    rule = get_rule.call each_ext
                    stack << rule if rule != nil
                end
                stack.each do |rule|
                    rules << rule
                end
            else
                rule = get_rule.call info
                rules << rule if rule != nil
            end
            return rules
        end

        # make data for header rules option
        # @param hash info
        # @return array
        def self.get_header_rules(info)
            rules = []

            # for :all
            headers = get_header_rules_field info['all']
            rules << [:all, headers] if headers.size > 0

            # for :directory
            if info['directory'] != nil
                get_rule = lambda do |data|
                    rule = nil
                    if data.is_a?(Hash) && data.has_key?('target')
                        dir = data.delete 'target'
                        dir = "/#{dir}" if !dir.start_with? '/'
                        headers = get_header_rules_field data
                        rule = [dir, headers] if headers.size > 0
                    end
                    return rule
                end
                rules_for_dir = get_header_rules_field_having_target info['directory'], get_rule
                rules_for_dir.each do |rule|
                    rules << rule
                end
           end

            # for :extension
            if info['extension'] != nil
                get_rule = lambda do |data|
                    rule = nil
                    if data.is_a?(Hash) && data.has_key?('target')
                        target = data.delete 'target'
                        ext    = target.split(',')
                        ext.map! do |v| v.strip end
                        headers = get_header_rules_field data
                        rule = [ext, headers] if headers.size > 0
                    end
                    return rule
                end
                rules_for_dir = get_header_rules_field_having_target info['extension'], get_rule
                rules_for_dir.each do |rule|
                    rules << rule
                end
            end

            # for :regexp
            if info['regexp'] != nil
                get_rule = lambda do |data|
                    rule = nil
                    if data.is_a?(Hash) && data.has_key?('target')
                        target = data.delete 'target'
                        if data['ignore_case'] == true
                            regexp = Regexp.new target, Regexp::IGNORECASE
                        else
                            regexp = Regexp.new target
                        end
                        headers = get_header_rules_field data
                        rule = [regexp, headers] if headers.size > 0
                    end
                    return rule
                end
                rules_for_dir = get_header_rules_field_having_target info['regexp'], get_rule
                rules_for_dir.each do |rule|
                    rules << rule
                end
            end

            # for :fonts
            headers = get_header_rules_field info['fonts']
            rules << [:fonts, headers] if headers.size > 0

            return rules
        end

        # @return proc
        public
        def use_middlewares
            return Proc.new do
                # overwrite the core method of lib/rack/builder.rb
                def self.use(middleware, *args, &block)
                    @nekonote_middlewares = [] if !defined? @nekonote_middlewares
                    @nekonote_middlewares << middleware.to_s
                    super
                end

                # add the individual method
                def self.get_nekonote_middlewares
                    return @nekonote_middlewares
                end

                # evaluate middlewares.rb as Ruby codes
                path = Preference.instance.path_middlewares_rb
                begin
                    # run middlewares.rb
                    instance_eval IO.read path
                rescue => e
                    # when the web server deamonized it will be output into log/puma.stderr.log
                    warn <<EOS
#{PreferenceError::MSG_EVAL_MIDDLEWARES% path}

#{e.class}:
    #{e.message}

#{e.backtrace.join($/)}
EOS
                    exit 1
                end

                # display middleware list
                is_enabled_show_exceptions = false
                get_nekonote_middlewares.each do |middleware_name|
                    if middleware_name == 'Rack::ShowExceptions'
                        is_enabled_show_exceptions = true
                    end
                    puts " + Use -> #{middleware_name}"
                end

                Preference.instance.is_enabled_show_exceptions = is_enabled_show_exceptions
            end
        end

        # publishing for static files
        public
        def define_public_dir
            return Proc.new do |pref_public|
                # expected Hash only
                pref_public = {} if !pref_public.is_a? Hash

                options = {
                    :root => Nekonote.get_root_path + 'public'
                }

                # publish specific files only
                # define published directories under 'public'
                pub_dirs = []
                if pref_public['published_directory'].is_a? Array
                    pub_dirs = pref_public['published_directory']
                    pub_dirs.map! do |val|
                        if val.start_with? '/' 
                            val
                        else
                            '/' + val
                        end
                    end
                end
                if pub_dirs.count > 0
                    options[:urls] = pub_dirs
                end

                # define published files under 'public'
                pub_files = []
                if pref_public['published_file'].is_a? Array
                    pub_files = pref_public['published_file']
                    pub_files.map! do |val|
                        if val.start_with? '/' 
                            val
                        else
                            '/' + val
                        end
                    end
                end
                if pub_files.count > 0
                    if options[:urls].is_a? Array
                        options[:urls] = options[:urls] + pub_files
                    else
                        options[:urls] = pub_files
                    end
                end

                # add custom headers
                if pref_public['custom_header'].is_a? Hash
                    rules = ::Nekonote::Rackup.get_header_rules pref_public['custom_header']
                    if rules.size > 0
                        options[:header_rules] = rules
                    end
                end

                # register published static files
                use RackStatic, options
            end # end proc
        end

        # @return proc
        public
        def define_route
            return Proc.new do |pref_route|
                # load the common handler
                Nekonote.load_base_handler

                # load files under 'handler' direcotry
                Dir[File.expand_path('handler', Nekonote.get_root_path) + '/**/*.rb'].each do |file|
                    require file # TODO need auto loading
                end

                # get preferences for include
                pref_common = Preference.instance.get_route_include

                # define the routes
                routes = {}  # instance list of app
                paths  = []  # for duplicate check
                pref_route.each do |info|
                    # if include directive has been set, convert it to the directives and missing directives will be filled
                    if info[Preference::FIELD_ROUTE_INCLUDE].is_a? String
                        # include directive has been set in the route
                        if pref_common[info[Preference::FIELD_ROUTE_INCLUDE]].is_a? Hash
                            pref_common[info[Preference::FIELD_ROUTE_INCLUDE]].each_pair do |k, v|
                                if info[k] == nil
                                    info[k] = v
                                else
                                    # directive name is duplicate between route.yml and route_include.yml
                                    # values in route.yml takes precedence over values in route_include.yml that without method or params
                                    info[k] += ',' + v if k == Preference::FIELD_ROUTE_PARAMS || k == Preference::FIELD_ROUTE_ALLOW_METHOD
                                end
                            end
                            info.delete Preference::FIELD_ROUTE_INCLUDE
                        else
                            # no such field in route_include.yml
                            raise PreferenceError, PreferenceError::MSG_MISSING_INCLUDE% [info[Preference::FIELD_ROUTE_INCLUDE], Preference.instance.path_route_include_yml]
                        end
                    end

                    # difined path field?
                    path = info[Preference::FIELD_ROUTE_PATH]
                    if !path.is_a? String
                        raise PreferenceError, PreferenceError::MSG_MISSING_FIELD% [Preference::FIELD_ROUTE_PATH, Preference.instance.path_route_yml]
                    end

                    # having handler?
                    handler = info[Preference::FIELD_ROUTE_HANDLER]
                    if !handler.is_a? String
                        raise PreferenceError, PreferenceError::MSG_INVALID_HANDLER_NAME% "#{handler}"
                    end

                    # validation for the field 'page_cache_time'
                    if info[Preference::FIELD_ROUTE_PAGE_CACHE_TIME] != nil
                        page_cache_time = info[Preference::FIELD_ROUTE_PAGE_CACHE_TIME].to_i
                        if page_cache_time > 0
                            info[Preference::FIELD_ROUTE_PAGE_CACHE_TIME] = page_cache_time
                        else
                            raise Error, Error::MSG_INVALID_FIELD% [Preference::FIELD_ROUTE_PAGE_CACHE_TIME, Preference.instance.path_route_yml]
                        end
                    end

                    # set app
                    begin
                        routes[info[Preference::FIELD_ROUTE_PATH].strip] = Object.const_get(handler).new(info)
                    rescue NameError => e
                        Error.abort e
                    end

                    paths << path
                end

                # is there any duplicate path?
                if paths.size != paths.uniq.size
                    raise PreferenceError, PreferenceError::MSG_DUPLICATE_PATH% Preference.instance.path_route_yml
                end

                run URLMapper.new routes
            end # end proc
        end # end #define_route
    end
end
