#!/usr/bin/env ruby
# Creates an empty .rgit repository in the current folder

require "fileutils" # gives us mkdir_p (creates nested folders in one go)

RGIT_DIRECTORY = ".rgit"

# Don't overwrite an existing repo
# (The tutorial uses Dir.exists?, which was removed in newer Ruby)
if Dir.exist?(RGIT_DIRECTORY)
  $stderr.puts "Existing rgit project in #{Dir.pwd}"
  exit 1
end

# .rgit/objects stores file contents (blobs), folders (trees) and commits
def build_objects_directory
  FileUtils.mkdir_p(File.join(RGIT_DIRECTORY, "objects", "info"))
  FileUtils.mkdir_p(File.join(RGIT_DIRECTORY, "objects", "pack"))
end

# .rgit/refs stores branches and tags, as files that hold a commit hash
def build_refs_directory
  FileUtils.mkdir_p(File.join(RGIT_DIRECTORY, "refs", "heads"))
  FileUtils.mkdir_p(File.join(RGIT_DIRECTORY, "refs", "tags"))
end

# HEAD says which branch you're on. It points to a branch, not a commit
def initialize_head
  File.write(File.join(RGIT_DIRECTORY, "HEAD"), "ref: refs/heads/master\n")
end

build_objects_directory
build_refs_directory
initialize_head

puts "Initialized empty rgit repository in #{File.expand_path(RGIT_DIRECTORY)}"