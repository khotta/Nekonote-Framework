begin
    require_relative 'loader'
rescue StandardError, ScriptError => e
    Nekonote::Error.abort e
end
