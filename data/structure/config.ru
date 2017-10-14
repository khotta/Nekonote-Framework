# This is a configuration file about Rack which created automatically.
# You must NOT delete this file.

# for starting web server withouht 'nekonote server'
if !defined? Nekonote
    require 'bundler/setup'
    require 'nekonote'
end

# set-up your application
Nekonote.set_root File.expand_path(File.dirname(__FILE__)) if !Nekonote.has_root?
self.instance_exec &Nekonote::Rackup.instance.use_middlewares
self.instance_exec Nekonote::Preference.instance.get_public, &Nekonote::Rackup.instance.define_public_dir
self.instance_exec Nekonote::Preference.instance.get_route,  &Nekonote::Rackup.instance.define_route
