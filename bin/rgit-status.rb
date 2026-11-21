#!/usr/bin/env ruby
# Shows what's staged, what's changed but not staged, and what's untracked
$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require "rgit/object"
require "rgit/index"
require "rgit/refs"
require "rgit/commit"
require "rgit/tree"

unless Dir.exist?(".rgit")
  $stderr.puts "Not an rgit project (run 'rgit init' first)"
  exit 1
end

# Terminal colour codes: green = staged, red = not staged (same as git)
GREEN = "\e[32m"
RED   = "\e[31m"
RESET = "\e[0m"

# --- The three versions, all as { path => sha } ---

# 1. The last commit (empty before the first commit)
head_sha   = RGit::Refs.head_commit
head_files = head_sha ? RGit::Tree.flatten(RGit::Commit.new(head_sha).tree) : {}

# 2. The index
index_files = RGit::Index.load

# 3. The working folder. FNM_DOTMATCH includes dotfiles like .env,
#    but the .rgit folder itself is skipped.
working_files = Dir.glob("**/*", File::FNM_DOTMATCH)
  .select { |path| File.file?(path) }
  .reject { |path| path.start_with?(".rgit/") }
  .to_h   { |path| [path, RGit::Object.hash_content(File.binread(path))] }

# --- Compare ---

# HEAD vs index: what the next commit would change
staged = []
(head_files.keys | index_files.keys).sort.each do |path|  # | = union, no duplicates
  if !head_files.key?(path)
    staged << ["new file", path]
  elsif !index_files.key?(path)
    staged << ["deleted", path]
  elsif head_files[path] != index_files[path]
    staged << ["modified", path]
  end
end

# Index vs working folder: changes you haven't run "add" on yet
unstaged = []
index_files.keys.sort.each do |path|
  if !working_files.key?(path)
    unstaged << ["deleted", path]
  elsif working_files[path] != index_files[path]
    unstaged << ["modified", path]
  end
end

# On disk, but rgit has never been told about them
untracked = (working_files.keys - index_files.keys).sort

# --- Print ---

def print_changes(title, changes, color)
  return if changes.empty?
  puts "\n#{title}:"
  changes.each do |label, path|
    puts "  #{color}#{"#{label}:".ljust(12)}#{path}#{RESET}"  # line up the paths
  end
end

puts "On branch #{RGit::Refs.current_branch}"
puts "\nNo commits yet" unless head_sha

print_changes("Changes to be committed", staged, GREEN)
print_changes("Changes not staged for commit", unstaged, RED)

unless untracked.empty?
  puts "\nUntracked files:"
  untracked.each { |path| puts "  #{RED}#{path}#{RESET}" }
end

if staged.empty? && unstaged.empty? && untracked.empty?
  puts "\nnothing to commit, working tree clean"
end