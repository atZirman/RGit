#!/usr/bin/env ruby
# Prints the decompressed contents of an object: rgit cat-file <sha>
$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require "rgit/object"

sha = ARGV.first
abort "usage: rgit cat-file <sha>" if sha.nil?
print RGit::Object.read(sha)