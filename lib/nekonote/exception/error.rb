module Nekonote
    # static methods class
    class Error < StandardError
        SPACE = '    '
        MSG_MISSING_ENV          = %(Environment variable NEKONOTE_ENV is empty or invalid environment name is set.)
        MSG_MISSING_ROOT         = %(Not found a root directory to the application structure.)
        MSG_NOT_DEFINED_ROOT     = %(Application root has not set yet.)
        MSG_MISSING_FILE         = %(No such file '%s' or can't read it.)
        MSG_MISSING_DIR          = %(No such directory '%s' or can't read it.)
        MSG_MISSING_RACKUP       = %(No found config.ru under '%s' or can't read it.)
        MSG_LACK_FIELD_IN_YAML   = %(Lack of the required field '%s'. Please check if '%s' is set properly.)
        MSG_EMPTY_YAML           = %('%s' is empty. You must configure something.)
        MSG_WRONG_ROOT           = %(You'd better run the command at the application root, or --root option will solve the problem.)
        MSG_WRONG_TYPE           = %([%s] is invalid type. It must be passed [%s].)
        MSG_MISSING_FIELD        = %(The required field '%s' was not found in '%s'.)
        MSG_INVALID_FIELD        = %(Invalid format field '%s' in '%s'.)
        MSG_MISSING_CONST        = %(Not found such class or module or contant -> '%s'.)
        MSG_EMPTY_FILE_NOT_EMPTY = %('%s' is not empty. Failed to create an empty file.)
        MSG_NOT_FOUND_DIRECTIVE  = %('%s' directive is required in '%s')

        # write message as warning to log file if logging is enabled
        # @param string msg
        def self.warning(msg)
            logging_warn msg

            begin
                if Nekonote.from_cli?
                    warn 'Warning: ' + msg
                end
            rescue
            end
        end

        # @param StandardError e
        def self.abort(e)
            # if executed from cli do not throw exception
            if Nekonote.from_cli?
                warn "#{e.class}; =(-x-=;)" + $/
                warn SPACE + e.message + $/ + $/
                if !e.is_a? Nekonote::Error
                    warn e.backtrace
                end
                exit 1
            end

            # logging when logger is enabled
            logging_error e

            raise e
        end

        # write error informaton to log file if logging is enabled
        # @param string msg
        def self.logging_warn(msg)
            begin
                if Nekonote.need_logging_exception?
                    logwrite msg, Nekonote::Logger::WARN
                    Nekonote::Logger.instance.set_level_default
                end
            rescue
            end
        end

        # write error informaton to log file if logging is enabled
        # @param StandardError e
        def self.logging_error(e)
            begin
                if Nekonote.need_logging_exception?
                    msg = %(#{e.class} - #{e.message}) + $/ + e.backtrace.join($/)
                    logwrite msg, Nekonote::Logger::FATAL
                    Nekonote::Logger.instance.set_level_default
                end
            rescue
            end
        end
    end
end
