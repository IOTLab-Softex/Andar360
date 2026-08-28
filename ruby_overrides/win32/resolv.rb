# frozen_string_literal: true

# Work around Windows application-control policies that block Ruby's unsigned
# native encoding extensions while win32/registry is loading.
module Win32
  module Resolv
    def self.get_hosts_path
      windows_dir = ENV.fetch("SystemRoot", "C:/Windows")
      hosts_path = File.join(windows_dir, "System32", "drivers", "etc", "hosts")
      File.exist?(hosts_path) ? hosts_path : nil
    end

    def self.get_resolv_info
      nameservers = ENV.fetch("RUBY_RESOLV_NAMESERVERS", "")
        .split(/[,\s;]+/)
        .reject(&:empty?)

      nameservers = %w[1.1.1.1 8.8.8.8] if nameservers.empty?

      [ nil, nameservers ]
    end
  end
end
