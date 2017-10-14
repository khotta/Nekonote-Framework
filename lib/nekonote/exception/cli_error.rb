module Nekonote
    class CLIError < Error
        MSG_PERMIT_MAKE_DIR = %{Failed to generate an application structure in '%s' because of invalid permission or not found.}
        MSG_UNABLE_TO_LOAD  = %(Unable to load %s. Did you really install it?)

        MSG_MISSING_AFTER_NEW     = %(Please set something after new.)
        MSG_MISSING_NEW_PATH      = %(Please set some name to generate.)
        MSG_MISSING_STRUCTURE_DIR = %(The specified directory was not found. Please make sure '%s' directory exists on your server.)
        MSG_MISSING_DEST_PATH     = %('%s' was not found in the application structure.)
        MSG_MISSING_AFTER_SERVER  = %('nekonote server' requires some sub-command.)

        MSG_INVALID_NEW_NAME      = %(Invalid name '%s'.)
        MSG_INVALID_HANDLER_NAME  = %(Invalid handler name '%s'.)
        MSG_INVALID_TEMPLATE_NAME = %(Invalid template name '%s'.)
        MSG_INVALID_LAYOUT_NAME   = %(Invalid layout name '%s'.)
        MSG_INVALID_ENV_NAME      = %(Invalid environment name '%s'.)

        MSG_ALREADY_EXISTS_APP      = %('%s' exists already. You need to remove it at first.)
        MSG_ALREADY_EXISTS_HANDLER  = %(Handler '%s' exists already. Nothing to do.)
        MSG_ALREADY_EXISTS_TEMPLATE = %(Template '%s' exists already. Nothing to do.)
        MSG_ALREADY_EXISTS_LAYOUT   = %(Layout '%s' exists already. Nothing to do.)
        MSG_ALREADY_EXISTS_ENV      = %(Environment '%s' exists already. Nothing to do.)

        MSG_FAILED_CREATE_HANDLER  = %(Failed to create a handler by the following reason '%s')
        MSG_FAILED_CREATE_TEMPLATE = %(Failed to create a template by the following reason '%s')
        MSG_FAILED_CREATE_LAYOUT   = %(Failed to create a layout by the following reason '%s')
        MSG_FAILED_GEN_DIR_BY_FILE = %(Failed to create a directory '%s'. There is the file which the same name.)
        MSG_FAILED_START_SERVER    = %(Failed to start the web server. Please check the error message.)

        MSG_UNKNOWN_AFTER_NEW    = %(Unknown sub command 'nekonote new %s'.)
        MSG_UNKNOWN_AFTER_SERVER = %(Unknown sub command 'nekonote server %s'.)
        MSG_UNKNOWN_SUB_COMMAND  = %(Unknown sub command '%s'. Typing 'nekonote -h' will help you.)
    end
end
