#!/usr/bin/env ruby
# Turns the index into tree objects, writes a commit, and moves the branch to it

# Let us require files from GetInRuby/lib
$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require "rgit/object"
require "time"

RGIT_DIRECTORY = ".rgit"
INDEX_PATH     = File.join(RGIT_DIRECTORY, "index")
HEAD_PATH      = File.join(RGIT_DIRECTORY, "HEAD")

unless Dir.exist?(RGIT_DIRECTORY)
  $stderr.puts "Not an rgit project (run 'rgit init' first)"
  exit 1
end


# --- Reading the index ---

# Each index line is "<sha> <path>". split(" ", 2) splits only on the
# first space, so paths containing spaces still work.
def index_files
  return [] unless File.exist?(INDEX_PATH)
  File.readlines(INDEX_PATH, chomp: true).reject(&:empty?)
end

# Turns flat paths into a nested hash that looks like the folder structure:
#   "hello.txt", "src/app.rb"
#   => { "hello.txt" => "<sha>", "src" => { "app.rb" => "<sha>" } }
def index_tree
  tree = {}
  index_files.each do |line|
    sha, path = line.split(" ", 2)
    *folders, filename = path.split("/")

    # Walk down (and create) one nested hash per folder
    folder = folders.reduce(tree) { |node, name| node[name] ||= {} }
    folder[filename] = sha  # later "add"s of the same file win
  end
  tree
end

# --- Writing objects ---

# Recursively writes one tree object per folder and returns its sha.
# Subfolders are written first, because the parent needs their shas.
def build_tree(tree)
  lines = tree.sort.map do |name, value|
    if value.is_a?(Hash)
      "tree #{build_tree(value)} #{name}"  # a subfolder
    else
      "blob #{value} #{name}"              # a file
    end
  end
  RGit::Object.write(lines.join("\n") + "\n")
end

# The branch HEAD points to, e.g. "refs/heads/master"
def current_ref
  File.read(HEAD_PATH).strip.sub("ref: ", "")
end

# The latest commit on this branch, or nil if this is the first commit
def parent_commit
  ref_path = File.join(RGIT_DIRECTORY, current_ref)
  File.exist?(ref_path) ? File.read(ref_path).strip : nil
end

# The message comes from -m "...", or from your editor if -m isn't given
def commit_message
  if (i = ARGV.index("-m"))
    return ARGV[i + 1].to_s
  end

  message_path = File.join(RGIT_DIRECTORY, "COMMIT_EDITMSG")
  File.write(message_path, "\n# Write your commit message above. Lines starting with # are ignored.\n")

  # Falls back to VS Code; --wait makes Ruby pause until you close the tab
  editor = ENV["VISUAL"] || ENV["EDITOR"] || "code --wait"
  system("#{editor} \"#{message_path}\"")

  File.readlines(message_path).reject { |l| l.start_with?("#") }.join.strip
end

def build_commit(tree_sha:, message:)
  lines = ["tree #{tree_sha}"]
  lines << "parent #{parent_commit}" if parent_commit
  lines << "author user #{Time.now.iso8601}"
  lines << ""        # blank line separates the header from the message
  lines << message
  RGit::Object.write(lines.join("\n") + "\n")
end

# Moves the branch to the new commit
def update_ref(commit_sha)
  File.write(File.join(RGIT_DIRECTORY, current_ref), commit_sha + "\n")
end

def clear_index
  File.write(INDEX_PATH, "")
end

# --- Run ---

if index_files.empty?
  $stderr.puts "Nothing to commit"
  exit 1
end

message = commit_message
if message.empty?
  $stderr.puts "Aborting commit due to empty commit message"
  exit 1
end

tree_sha   = build_tree(index_tree)
commit_sha = build_commit(tree_sha: tree_sha, message: message)
update_ref(commit_sha)
clear_index

puts "[#{current_ref.split('/').last} #{commit_sha[0..6]}] #{message.lines.first.strip}"