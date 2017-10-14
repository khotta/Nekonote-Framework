class WelcomeHandler < BaseHandler
    def index
        variables = {
            'version'     => Nekonote::VERSION,
            'description' => Nekonote::DESCRIPTION,
            'root'        => Nekonote.get_root,
            'env'         => Nekonote::Env.current
        }
        __assign variables
    end
end
