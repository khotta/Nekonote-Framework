module Nekonote
    @@env ||= ENV['NEKONOTE_ENV']
    @@root                   = nil
    @@root_path              = nil
    @@logger_enabled         = nil
    @@logger_write_exception = nil

    # set root directory to the application
    # @param string root
    def self.set_root(root)
        if root.is_a?(String) && @@root != ''
            root      = File.expand_path root
            root_path = root + '/'
            @@root      ||= root
            @@root_path ||= root_path
        else
            # root is empty
            raise Error, Error::MSG_MISSING_ROOT
        end

        # root exist?
        if !Util::Filer.available_dir? @@root
            raise Error, Error::MSG_MISSING_DIR% @@root
        end

        # config.ru exist?
        if !Util::Filer.available_file? @@root_path + 'config.ru'
            msg  = Error::MSG_MISSING_RACKUP% @@root_path + $/
            msg += Error::SPACE + Error::MSG_WRONG_ROOT
            raise Error, msg
        end
    end

    # @return string
    def self.get_env
        if !has_valid_env?
            raise Error, Error::MSG_MISSING_ENV
        end
        return @@env
    end

    # @return bool
    def self.has_valid_env?
        return @@env.is_a?(String) && @@env != '' && @@env.match('/') == nil && @@env.match('\*') == nil
    end

    # @return string
    def self.get_root
        if @@root == nil
            raise Error, Error::MSG_NOT_DEFINED_ROOT
        end
        return @@root
    end

    # @return string
    def self.get_root_path
        if @@root_path == nil
            raise Error, Error::MSG_NOT_DEFINED_ROOT
        end
        return @@root_path
    end

    # @return bool
    def self.has_root?
        return @@root != nil
    end

    # @return bool
    def self.from_cli?
        return defined?(@@from_cli) && @@from_cli
    end

    # logger is enabled or not?
    # @return bool
    def self.logger_enabled?
        return @@logger_enabled
    end

    # @return bool
    def self.need_logging_exception?
        return logger_enabled? && @@logger_write_exception
    end

    # load and initialize logger if it has been enabled
    def self.init_logger
        pref_logger = Preference.instance.get_logger

        if pref_logger['write_exception'] == true
            @@logger_write_exception = true
        else
            @@logger_write_exception = false
        end

        if pref_logger['enabled'] == true
            # the method for logger will be defined
            Logger.instance.init pref_logger
            @@logger_enabled = true
        else
            # remove the defined method for logging
            if Object.respond_to? :logwrite, true
                Object.class_eval { remove_method :logwrite }
            end
            @@logger_enabled = false
        end
    end

    # load base handler from app root
    def self.load_base_handler
        begin
            require get_root_path + 'handler/base'

        rescue LoadError
            raise LoadError, Error::MSG_MISSING_FILE% path
        end
    end
end
