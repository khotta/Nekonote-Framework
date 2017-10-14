module Nekonote
    class PreferenceError < Error
        MSG_UNDEFINED_FIELD      = %(Undefined field '%s'.)
        MSG_WRONG_YAML_SYNTAX    = %(The yaml file '%s' is invalid syntax.)
        MSG_MISSING_INCLUDE      = %(No such field '%s' in %s.)
        MSG_INVALID_HANDLER_NAME = %(Handler class name '%s' is invalid.)
        MSG_NO_SUCH_HANDLER      = %(No such handler class '%s'. You must make it at first.)
        MSG_DUPLICATE_PATH       = %(There is the duplicate path in %s. Values of 'path' directive are supposed to be uniq.)
        MSG_EVAL_MIDDLEWARES     = %(Unable to evaluate '%s' because there's something wrong.)
    end
end
