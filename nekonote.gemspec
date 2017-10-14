# Nekonote Framwork
#
# Simple and lightweight Rack-based web framework
# Copyright (c) 2017, Kazuya Hotta

require File.expand_path '../lib/nekonote/spec', __FILE__

Gem::Specification.new do |s|
    s.name                 = Nekonote::LIBS_NAME
    s.version              = Nekonote::VERSION
    s.homepage             = Nekonote::HOMEPAGE
    s.summary              = Nekonote::SUMMARY
    s.description          = Nekonote::DESCRIPTION
    s.authors              = ['khotta']
    s.email                = ['khotta116@gmail.com']
    s.license              = 'MIT'
    s.post_install_message = Nekonote::INSTALL_MESSAGE

    # include files to this gem package.
    s.files  = Dir['LICENSE']
    s.files << Dir['README.md']
    s.files += Dir['bin/nekonote']
    Dir['data/**/*'].each do |file|
        s.files << file
    end
    Dir['lib/**/*'].each do |file|
        s.files << file
    end
    Dir['lib/**/.gitkeep'].each do |file|
        s.files << file
    end
    Dir['data/**/.gitkeep'].each do |file|
        s.files << file
    end

    # required path
    s.require_paths = ['lib']

    # executable command
    s.executables = s.files.grep(%r{^bin/}) do |f|
        File.basename f
    end

    # required ruby version
    s.required_ruby_version = '>= 2.3.0'

    # dependent library
    s.add_dependency 'color_echo', '~> 3.1', '>= 3.1.1'
end
