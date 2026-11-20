#!/user/bin/env ruby
# Dispatcher: "rgit init" runs bin/rgit-init, "rgit add" runs bin/rgit-add, etc.

# No Command given? Show how to use it and exit with an error code
if ARGV.empty?
  $stderr.puts "usage: rgit <command> [<args>]"
  exit 1
end

# ARGV.shift removes the first argument ("init") and return it
# Whatever is left in ARGV gets passed on to the subcommand
command = ARGV.shift

# Build the path to the subcommand, in the same folder as this file
command_path = File.expand_path("../rgit-#{command}.rb", __FILE__)

# Unknown command? Complain and exit
unless File.exist?(command_path)
  $stderr.puts "rgit: '#{command}' is not an rgit command"
  exit 1
end

# Replace this process with the subcommand
# The tutorial just does exec(command_path), but windows  can't read the
# "#!user/bin/env ruby" line, so we start Ruby ourselves.
# RbConfig.ruby is the full path to the ruby.exe that's running right now.
exec(RbConfig.ruby, command_path, *ARGV)