# Reads a tree and all its subtrees back into flat paths:
#   { "hello.txt" => "<sha>", "src/app.rb" => "<sha>" }
require "rgit/object"

module RGit
  module Tree
    def self.flatten(tree_sha, prefix = "")
      files = {}

      # Each line in a tree is "<type> <sha> <name>"
      Object.read(tree_sha).each_line(chomp: true) do |line|
        type, sha, name = line.split(" ", 3)  # 3 parts, so names with spaces work
        path = prefix + name

        if type == "tree"
          files.merge!(flatten(sha, "#{path}/"))  # go into the subfolder
        else
          files[path] = sha
        end
      end

      files
    end
  end
end