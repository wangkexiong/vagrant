#!/usr/bin/env ruby

# Only valid for hyperv and virtualbox provider

def set_cpus(config, value)
  ["hyperv", "virtualbox"].each do |provider|
    config.vm.provider provider do |v, override|
      v.cpus = value
    end
  end
end

# Number of megabytes allocated to VM at startup
def set_memory(config, value)
  ["hyperv", "virtualbox"].each do |provider|
    config.vm.provider provider do |v, override|
      v.memory = value
    end
  end
end

def set_vmname(config, value)
  ["hyperv", "virtualbox"].each do |provider|
    config.vm.provider provider do |v, override|
      v.vmname = value
    end
  end
end
