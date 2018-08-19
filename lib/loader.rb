# for bundler
require 'bundler'
require 'bundler/setup'

# ========================================
# auto loading standard and gem libraries
# ========================================
# standard libraries
# TODO need namespace for avoiding declaration
autoload :Psych, 'yaml'
autoload :YAML, 'yaml'
autoload :Singleton, 'singleton'
autoload :FileUtils, 'fileutils'
autoload :URI, 'uri'

# dependent gem libraries
autoload :Rack, 'rack'
autoload :Liquid, 'liquid'
autoload :Puma, 'puma/control_cli'
autoload :SimpleRotate, 'simple_rotate'

# optional gem libraries
autoload :ConnectionPool, 'connection_pool'
# for Dalli
autoload :Dalli, 'dalli'
begin
    module Rack
        module Session
            autoload :Dalli, 'rack/session/dalli'
        end
    end
rescue LoadError
    # ignore LoadError in case the set-up hasn't completed yet
end

# ==============================
# auto loading internal files
# ==============================
module Nekonote
    @@lib_root_path = File.expand_path(File.dirname(__FILE__)) + '/nekonote/'
    def self.get_lib_root_path
        return @@lib_root_path
    end

    # extends Nekonote module
    require Nekonote.get_lib_root_path + 'spec'
    require Nekonote.get_lib_root_path + 'core'

    module Util
        autoload :Filer, Nekonote.get_lib_root_path + 'util/filer'
        autoload :Process, Nekonote.get_lib_root_path + 'util/process'
    end

    [
        {:class => :Error,           :file => 'exception/error'},
        {:class => :PageCacheError,  :file => 'exception/page_cache_error'},
        {:class => :PreferenceError, :file => 'exception/preference_error'},
        {:class => :ViewError,       :file => 'exception/view_error'},
        {:class => :CLIError,        :file => 'exception/cli_error'},
        {:class => :HandlerError,    :file => 'exception/handler_error'},
        {:class => :LoggerError,     :file => 'exception/logger_error'},
        {:class => :YamlAccess,      :file => 'yaml_access'},
        {:class => :Env,             :file => 'env'},
        {:class => :Preference,      :file => 'preference'},
        {:class => :Setting,         :file => 'setting'},
        {:class => :PageCache,       :file => 'page_cache'},
        {:class => :View,            :file => 'view'},
        {:class => :TagEnvGet,       :file => 'liquid/tag_env_get'},
        {:class => :TagSettingGet,   :file => 'liquid/tag_setting_get'},
        {:class => :TagPartial,      :file => 'liquid/tag_partial'},
        {:class => :Request,         :file => 'request'},
        {:class => :Handler,         :file => 'handler.rb'},
        {:class => :Rackup,          :file => 'rackup'},
        {:class => :Cli,             :file => 'cli'},
        {:class => :CmdParser,       :file => 'cmd_parser'},
        {:class => :Puma,            :file => 'puma'},
        {:class => :RackStaticFile , :file => 'rack/rack_static_file'},
        {:class => :RackStatic,      :file => 'rack/rack_static'},
        {:class => :URLMapper,       :file => 'rack/url_mapper'},
        {:class => :Logger,          :file => 'logger'}
    ].each do |data|
        autoload data[:class], Nekonote.get_lib_root_path + data[:file]
    end
end
