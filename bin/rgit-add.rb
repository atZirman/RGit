#!/usr/bin/env ruby
# Stages one or more files: rgit add <file> [<file> ...]
$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require "rgit/object"
require "rgit/index"

unless Dir.exist?(".rgit")
  $stderr.puts "Not an rgit project (run 'rgit init' first)"
  exit 1
end

if ARGV.empty?
  $stderr.puts "usage: rgit add <file> [<file> ...]"
  exit 1
end

# Check every file BEFORE changing anything, so a typo doesn't leave
# the index half-updated
missing = ARGV.reject { |path| File.file?(path) }
unless missing.empty?
  missing.each { |path| $stderr.puts "rgit: '#{path}' did not match any files" }
  exit 1
end

index = RGit::Index.load

ARGV.each do |path|
  # Store paths the same way on every OS: forward slashes, no leading "./"
  clean_path = path.tr("\\", "/").delete_prefix("./")

  # Save the blob. Adding the same path again replaces the old entry.
  index[clean_path] = RGit::Object.write(File.binread(path))
end

RGit::Index.save(index)