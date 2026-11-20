#!/usr/bin/env ruby
# Shows history: starts at the latest commit and follows the parent links back
$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require "rgit/refs"
require "rgit/commit"

sha = RGit::Refs.head_commit
abort "fatal: your current branch '#{RGit::Refs.current_branch}' does not have any commits yet" unless sha

# Keep going until we reach the first commit, which has no parent
while sha
  commit = RGit::Commit.new(sha)

  puts "commit #{commit.sha}"
  puts "Author: #{commit.author}"
  puts "Date:   #{commit.time}"
  puts
  commit.message.each_line { |line| puts "    #{line}" }  # indented, like git
  puts

  sha = commit.parent
end