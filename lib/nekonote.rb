begin
    require_relative 'loader'
rescue StandardError, ScriptError => e
    begin
        Nekonote::Error.abort e
    rescue
        raise e
    end
end
