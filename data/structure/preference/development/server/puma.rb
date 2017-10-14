#!/usr/bin/env puma
# Configuration for puma web server.
# Please check the reference manual of Puma to get more information.

# document root
# It's supposed to be set absolute path to application root.
_app_root = 'REPLACE_ME_TO_APP_ROOT'

# host address to bind
_host = '0.0.0.0'

# listen port
_port = '2002'

# the directory to oparate out of
directory _app_root

# where bind to
# e.g. bind 'unix:///var/run/puma.sock'
# e.g. bind 'unix:///var/run/puma.sock?umask=0111'
# e.g. bind "ssl://#{_host}:#{_port}?key=path_to_key&cert=path_to_cert"
bind "tcp://#{_host}:#{_port}"

# for SSL you may use this instead of 'bind'
# ssl_bind _host, _port, {
#   key: path_to_key,
#   cert: path_to_cert
# }

# Minimum to maximum number of threads to answer.
threads 0, 16

# The environment in which the rack's app will run.
environment 'none'

# true to server is daemonize
daemonize true

# PID and state for puma web server
pidfile "#{_app_root}/tmp/pids/puma.pid"
state_path "#{_app_root}/tmp/pids/puma.state"

# log messages redrect to
stdout_redirect "#{_app_root}/log/puma.stdout.log", "#{_app_root}/log/puma.stderr.log"
# If you prefer to that output is appended, please pass true to the third parameter.
#stdout_redirect "#{_app_root}/log/puma.stdout.log", "#{_app_root}/log/puma.stderr.log", true

# Commented out to disable request logging.
# quiet

# -------------
# Cluster mode
# -------------
# How many worker precesses to run?
# The default is 0. It's not clusterized.
# workers 2

# Worker processes will be restarted when worker processes couldn't resond within this time.
# It's not request time out. It's used for detecting malfunctional woker processes.
# worker_timeout 60

# Woker processes' timeout for booting
# worker_boot_timeout 60
