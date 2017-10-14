module Nekonote
    class Logger
        include Singleton
        DEBUG = 0
        INFO  = 1
        WARN  = 2
        ERROR = 3
        FATAL = 4

        public
        def init(pref)
            logf  = pref['logfile']%Nekonote.get_env
            limit = pref['limit']
            keep  = pref['keep'].to_i

            if logf == nil || limit == nil || keep == nil
                raise LoggerError, LoggerError::MSG_MISSING_LOGFILE
            end

            if !logf.start_with? '/'
                # when log file path is relative
                logf = Nekonote.get_root_path + logf
            end

            # initialize logger
            @logger = SimpleRotate.instance
            set_optional pref
            begin
                @logger.init logf, limit, keep
            rescue
                msg = $/ + Error::SPACE + "Logger definitions are: logfile = #{logf}, limit = #{limit}, keep = #{keep}"
                raise LoggerError, LoggerError::MSG_FAILED_INITIALIZE%[ENV['USER'], logf] + msg
            end

            # set default log level
            @default_log_level = get_log_level_by_name pref['default_log_level']
            switch_level @default_log_level
        end

        # @param mixed msg
        public
        def write(msg, level = nil)
            if level != nil
                switch_level level
            end
            @logger << msg
        end

        public
        def set_level_default
            switch_level @default_log_level
        end

        # @param string log_level_name
        private
        def get_log_level_by_name(log_level_name)
            case log_level_name
            when 'debug'
                level = DEBUG
            when 'info'
                level = INFO
            when 'warn'
                level = WARN
            when 'error'
                level = ERROR
            when 'fatal'
                level = FATAL
            else
                # set default level for missing or unknown value is given
                level = INFO
            end
            return level
        end

        # @param int level
        private
        def switch_level(level)
            case level
            when DEBUG
                @logger.debug
            when INFO
                @logger.info
            when WARN
                @logger.warn
            when ERROR
                @logger.error
            when FATAL
                @logger.fatal
            else
                raise LoggerError. LoggerError::MSG_UNDIFINED_LOG_LEVEL
            end
        end

        # set optional preferences to @logger
        # @param array pref
        private
        def set_optional(pref)
            begin
                @logger.logging_format = pref['format']['log']
                @logger.date_format    = pref['format']['datetime']
                @logger.threshold      = pref['threshold'].upcase
                @logger.sleep_time     = pref['sleeptime']

                if pref['compress']['enabled'] == true
                    @logger.compress_level pref['compress']['level']
                end

                if pref['with_stdout'] == true
                    @logger.with_stdout
                end

                if pref['verbose'] == false
                    @logger.silence
                end

                if pref['psync'] == true
                    @logger.psync
                end

                if pref['flush'] == true
                    @logger.enable_wflush
                end

            rescue
                raise LoggerError, LoggerError::MSG_FAILED_DEF_OPT
            end
        end
    end
end

# @param mixed msg
# @param int level
def logwrite(msg, level = nil)
    Nekonote::Logger.instance.write msg, level
end
