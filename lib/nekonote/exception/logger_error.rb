module Nekonote
    class LoggerError < Error
        MSG_MISSING_LOGFILE     = %(Lack of the required directives 'logfile' and 'keep' and 'limit' in logger.yml.)
        MSG_FAILED_INITIALIZE   = %(Failed to initialize logger. Wrong syntax in logger.yml or '%s' doesn't have a permission to create '%s'.)
        MSG_FAILED_DEF_OPT      = %(Failed to define optional value. Maybe there is wrong syntax in logger.yml. Please check the reference manual.)
        MSG_UNDIFINED_LOG_LEVEL = %(Undifined log level was given. Please check the reference manual.)
    end
end
