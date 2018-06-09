class ErrorHandler < BaseHandler
    def missing_route
        @subject = 'Invalid URL'
        @msg     = 'The URL does not match any route'
        @detail  = %('#{Nekonote::Env.get :REQUEST_URI}' is not valid URL.)
    end

    def wrong_http_method
        @subject = 'Unacceptable HTTP method'
        @msg     = 'You have accessed with the unacceptable HTTP method.'
    end

    def fatal
        @subject = 'Server Error'
        @msg     = 'You can not access this page temporary.'
    end

    def not_found
        @subject = 'No such resource'
        @msg     = %('#{Nekonote::Env.get :REQUEST_URI}' was not found on the server.)
    end

    # It will be called at last
    def __post
        # assign values to templates
        list = {}
        list['subject'] = @subject if defined?(@subject)
        list['msg']     = @msg     if defined?(@msg)
        list['detail']  = @detail  if defined?(@detail)
        __assign list

        # change the response code to not 500 but 200
        __set_code 200
    end
end
