# You may add any configurations of Rack middlewares here.
# Please prepend underscore to beginning of your variable name to avoid naming conficts.
# Some configuration are listed by default. You may set them enabling or disbaling.
#
# --------------------------------------------------------------------------
# Rack::Reloader
#   It reloads modified files without restarting nor reloading the web server.
# --------------------------------------------------------------------------
_cooldown = 10
use Rack::Reloader, _cooldown

# -------------------------------------------------------------------------------------------------
# Rack::ShowExceptions
#   A GUI based debugger. It's won't work when 'fatal' route is set in route_error.yml.
#   You are supposed to DISABLE this function on production environment for security reason.
# -------------------------------------------------------------------------------------------------
use Rack::ShowExceptions

# -------------------------------------------
# Rack::Auth::Basic
#   It provides Basic access authentication.
# -------------------------------------------
=begin
_realm    = 'Here is secret zone'
_username = 'username_here'
_passwd   = 'password_here'
use Rack::Auth::Basic, _realm do |username, passwd|
    username == _username && passwd == _passwd
end
=end

# --------------------------------------------
# Rack::Auth::Digest::MD5
#   It provides Digest access authentication.
# --------------------------------------------
=begin
_realm    = 'Here is secret zone'
_opaque   = 'replace_me' # this is supposed to be set to a long random string
_username = 'username_here'
_passwd   = 'password_here'
_pw = {_username => _passwd}
use Rack::Auth::Digest::MD5, _realm, _opaque do |username|
    _pw[username]
end
=end

# ==========================
# Preferences for Session Management
# ==========================
_key          = 'rack.session'
_domain       = nil
_path         = '/'
_expire_after = 3600
_secure       = false
_httponly     = false
_sidbits      = 128

_session_options = {
    :key          => _key,
    :domain       => _domain,
    :path         => _path,
    :expire_after => _expire_after,
    :secure       => _secure,
    :httponly     => _httponly,
    :sidbits      => _sidbits
}
_session_options[:domain] = _domain if _domain != nil

# ---------------------------------------------------------------------
# Rack::Session::Cookie
#   It provides cookie based simple session management.
# ---------------------------------------------------------------------
# use Rack::Session::Cookie, _session_options

# --------------------------------------------------------------------------------------
# Rack::Session::Pool
#   It provides property-based session management.
# --------------------------------------------------------------------------------------
=begin
_drop = false
_session_pool_options = {
    :drop => _drop
}
use Rack::Session::Pool, _session_options.merge(_session_pool_options)
=end

# ----------------------------------------------------------------------------------
# Rack::Session::Dalli
#   It provides memcached based session management.
#   You must add 'dalli' to your Gemefile and typing bundle install to use it.
# ----------------------------------------------------------------------------------
=begin
_servers = ['127.0.0.1:11211'] # you may add any number of servers by comma
_connection_pooling = false

# options for dalli client
_namespace  = 'nekonote.session'
_failover   = true
_threadsafe = true
_expires_in = 0
_compress   = false
_dalli_client_options = {
    :namespace  => _namespace,
    :failover   => _failover,
    :threadsafe => _threadsafe,
    :expires_in => _expires_in,
    :compress   => _compress
}

# options for connection pooling
# they will work when connection pooling is enbaled
_size    = 5
_timeout = 5
_dalli_pool_options = {
    :size    => _size,
    :timeout => _timeout
}

# setup dalli
require 'dalli'

if _connection_pooling
    # enable connection pooling
    _dalli_client = ::Dalli::Client.new _servers, _dalli_client_options
    _cache = ::ConnectionPool::Wrapper.new(_pool_options) {_dalli_client}
else
    # disable connection pooling
    _cache = ::Dalli::Client.new _servers, _dalli_client_options
end

_dalli_options = {
    :cache => _cache
}
use Rack::Session::Dalli, _session_options.merge(_dalli_options)
=end

# -----------------------------------------------------------------------------------------
# Rack::Access
#   It provides access restrcition based on IP address.
#   You must add 'rack-contrib' to your Gemefile and typing bundle install to use it.
# -----------------------------------------------------------------------------------------
# Restricting access by IP addresses.
# Note: You may append subnet mask to a IP address.
# Note: You may specify any number of ipmasks by comma.
=begin
_rules = {
    # '/location' => ['ipmasks' ,...]
    '/' => ['127.0.0.1'] #,...
}
require 'rack/contrib'
use Rack::Access, _rules
=end
