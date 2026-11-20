#!/usr/bin/env ruby
# Snapshots the index as trees, writes a commit, and moves the branch to it
$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require "rgit/object"
require "rgit/index"
require "rgit/refs"
require "rgit/commit"
require "time"

unless Dir.exist?(".rgit")
  $stderr.puts "Not an rgit project (run 'rgit init' first)"
  exit 1
end

# { "hello.txt" => sha, "src/app.rb" => sha }
#   => { "hello.txt" => sha, "src" => { "app.rb" => sha } }
def nest(entries)
  tree = {}
  entries.each do |path, sha|
    *folders, filename = path.split("/")
    folder = folders.reduce(tree) { |node, name| node[name] ||= {} }
    folder[filename] = sha
  end
  tree
end

# Writes one tree object per folder (subfolders first) and returns the root's sha
def build_tree(tree)
  lines = tree.sort.map do |name, value|
    if value.is_a?(Hash)
      "tree #{build_tree(value)} #{name}"
    else
      "blob #{value} #{name}"
    end
  end
  RGit::Object.write(lines.join("\n") + "\n")
end

# The message comes from -m "...", or from your editor if -m isn't given
def commit_message
  if (i = ARGV.index("-m"))
    return ARGV[i + 1].to_s.strip
  end

  path = File.join(".rgit", "COMMIT_EDITMSG")
  File.write(path, "\n# Write your commit message above. Lines starting with # are ignored.\n")
  editor = ENV["VISUAL"] || ENV["EDITOR"] || "code --wait"
  system("#{editor} \"#{path}\"")
  File.readlines(path).reject { |l| l.start_with?("#") }.join.strip
end

def build_commit(tree_sha:, parent:, message:)
  lines = ["tree #{tree_sha}"]
  lines << "parent #{parent}" if parent
  lines << "author user #{Time.now.iso8601}"
  lines << ""
  lines << message
  RGit::Object.write(lines.join("\n") + "\n")
end

# --- Run ---

entries = RGit::Index.load
if entries.empty?
  $stderr.puts "Nothing to commit (use 'rgit add' to stage files)"
  exit 1
end

# Build the tree BEFORE asking for a message, so you don't type a message
# only to be told there's nothing to commit
tree_sha = build_tree(nest(entries))
parent   = RGit::Refs.head_commit

# Same content gives the same tree sha, so a match means nothing changed
if parent && RGit::Commit.new(parent).tree == tree_sha
  $stderr.puts "Nothing to commit, no changes since the last commit"
  exit 1
end

message = commit_message
if message.empty?
  $stderr.puts "Aborting commit due to empty commit message"
  exit 1
end

commit_sha = build_commit(tree_sha: tree_sha, parent: parent, message: message)
RGit::Refs.update_head(commit_sha)

puts "[#{RGit::Refs.current_branch} #{commit_sha[0..6]}] #{message.lines.first.strip}"