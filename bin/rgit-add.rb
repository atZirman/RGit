#!/usr/bin/env ruby
# Stages a file: stores its compressed contents as a blob and revords it in the index

require "digest" # SHA-1 hashing
require "zlib" # Compression
require "fileutils" # mkdir_p

RGIT_DIRECTORY = ".rgit"
OBJECT_DIRECTORY = File.join(RGIT_DIRECTORY, "objects")
INDEX_PATH = File.join(RGIT_DIRECTORY, "index")

# Must be inside an rgit repo
unless Dir.exist?(RGIT_DIRECTORY)
  $stderr.puts "Not an rgit project (run 'rgit init' first)"
  exit 1
end

path = ARGV.first

# A file name is required, and the file has to exist
if path.nil?
  $stderr.puts "usage: rgit add <file>"
  exit 1
end

unless File.file?(path)
  $stderr.puts "rgit: '#{path}' did not match any files"
  exit 1
end

# binread reads the raw bytes. A plain File.read on Windows would turn 
# \r\n into \n, which changes the content and therefore the hash
contents = File.binread(path)

# 1. Fingerprint the contents
sha = Digest::SHA1.hexdigest(contents)

# 2. Compress the contents. This is the hash
blob = Zlib::Deflate.deflate(contents)

# 3. Save to objects/<first 2 chars>/<remaining 38 chars>
object_directory = File.join(OBJECT_DIRECTORY, sha[0..1])
FileUtils.mkdir_p(object_directory)
File.binwrite(File.join(object_directory, sha[2..]), blob)

# 4. Add a line to the index ("a" = append, don't overwrite)
File.open(INDEX_PATH, "a") do |index|
  index.puts "#{sha} #{path}"
end

