# BaseHandler class
#
# BaseHandler class is a mechanism for code reuse in each Handler classes.
# All Handler classes are supposed to be inherited from this class.

class BaseHandler < Nekonote::Handler
    # This method will be executed at first
    def __pre
    end

    # This method will be executed at last
    def __post
        if @custom_fields['page-title'].is_a? String
            base = __setting_get :site, :title
            if base != nil
                list = {:title => "#{@custom_fields['page-title']} - #{base}"}
                __assign list
            end
        end
    end
end
