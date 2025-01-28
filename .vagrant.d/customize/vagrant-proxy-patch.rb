#!/usr/bin/env ruby

# Monkey Patch
#   Vagrant 2.2.4 Loading seq: core plugins -> vagrant invoke (create environment) -> user plugins
#   Vagrant 2.0.4 Loading seq: core plugins -> user plugins -> vagrant invoke (create environment)
#
#   Which means for 2.0.4, during vagrant invoking,
#   the already loaded user plugins will be triggered by hook settings.
#   It does NOT need to load explicitly for file to be monkey patched......
#   Our patched code block will surely be loaded after the original code
#
#   While for 2.2.4, plugin hooked after vagrant environment created.
#   Our code block is loaded before plugin code could be triggered (lazy initialized).
#   To make monkey patch working, explicitly load the file needs to be patched before our code block...

if Vagrant.has_plugin? 'vagrant-proxyconf'
  pluginfo = Vagrant::Plugin::Manager.instance.installed_plugins['vagrant-proxyconf']
  plugindir = "#{Vagrant.user_data_path}/gems/#{pluginfo['ruby_version']}/gems/vagrant-proxyconf-#{pluginfo['installed_gem_version']}"
  monkey_patch = "#{plugindir}/lib/vagrant-proxyconf/action/base.rb"
  require monkey_patch if File.file?(monkey_patch)
end

module VagrantPlugins
  module ProxyConf
    class Action
      # Base class for proxy configuration Actions
      class Base
        @@machine_config = nil

        def sudo(cmd)
          stdout = ''
          stderr = ''

          retval = @machine.communicate.sudo(cmd, error_check: false) do |type, data|
            if type == :stderr
              stderr << data.chomp
            else
              stdout << data.chomp
            end
          end

          {:stdout => stdout, :stderr => stderr, :retval => retval}
        end

        def default_config
          config = @machine.config.proxy

          cmd = "ip addr | grep inet | grep -v inet6 | awk '{print $2}' | awk -F/ '{print $1}' | paste -s -d,"
          cmd_config = sudo(cmd)[:stdout]
          if cmd_config
            if config.no_proxy
              config.no_proxy = "#{cmd_config},#{config.no_proxy}"
            else
              config.no_proxy = "#{cmd_config}"
            end
          end

          config.no_proxy = config.no_proxy.split(',').uniq().join(',')
          @@machine_config = finalize_config(config)
        end
      end
    end
  end
end
