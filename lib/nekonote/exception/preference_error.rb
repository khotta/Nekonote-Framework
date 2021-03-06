module Nekonote
    class PreferenceError < Error
        MSG_UNDEFINED_FIELD      = %(Undefined field '%s'.)
        MSG_WRONG_YAML_SYNTAX    = %(The yaml file '%s' is invalid syntax.)
        MSG_MISSING_INCLUDE      = %(No such field '%s' in %s.)
        MSG_INVALID_HANDLER_NAME = %(Handler class name '%s' is invalid.)
        MSG_DUPLICATE_PATH       = %(There is the duplicate path in %s. Values of 'path' directive are supposed to be unique.)
        MSG_EVAL_MIDDLEWARES     = %(Failed to run '%s')
        MSG_FAILED_INI_HANDLER   = %(Failed to make a %s class object.)
    end
end
