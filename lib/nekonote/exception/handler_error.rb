module Nekonote
    class HandlerError < Error
        MSG_NO_ERROR_ROUTE      = %('%s' is required to handle this error.);
        MSG_MISSING_ERR_HANDLER = %(No Handler in route_error.yml.);
    end
end
