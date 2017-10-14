module Nekonote
    class RackStaticFile < ::Rack::File
        def fail(status, body, headers = {})
            if Preference.instance.has_error_route? Preference::FIELD_ROUTE_ERR_NOT_FOUND
                begin
                    # display custom error response
                    return ::Nekonote::Handler.call_error_handler Preference::FIELD_ROUTE_ERR_NOT_FOUND, Env.get_all
                rescue => e
                    Error.logging_error e
                    # error, default behavior
                    super
                end
            else
                # no error route, default behavior
                super
            end
        end
    end
end
