module Nekonote
    class ViewError < Error
        MSG_MISSING_TEMPLATE_FILE = %(Failed to load the tempalte file. No such file '%s')
        MSG_MISSING_LAYOUT_FILE   = %(Failed to load the layout file. No such file '%s')
        MSG_FAILED_TO_ASSIGN      = %(Failed to assign variables into templates. You gave wrong type. The expected type is Hash.)
    end
end
