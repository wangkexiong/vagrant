#!/usr/bin/env ruby

module VagrantPlugins
  module Kernel_V2
    class VMConfig < Vagrant.plugin("2", :config)
      def blabla_cpus=(value)
        ["hyperv", "virtualbox"].each do |provider|
          self.provider provider do |v, override|
            v.cpus = value
          end
        end
      end

      #Number of megabytes allocated to VM at startup
      def blabla_memory=(value)
        ["hyperv", "virtualbox"].each do |provider|
          self.provider provider do |v, override|
            v.memory = value
          end
        end
      end
    end
  end
end
