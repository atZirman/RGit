# Reads a commit object and splits it into its parts
require "rgit/object"

module RGit
  class Commit
    attr_reader :sha, :tree, :parent, :author, :time, :message

    def initialize(sha)
      @sha = sha

      # A commit is the header lines, a blank line, then the message
      header, @message = Object.read(sha).split("\n\n", 2)

      header.each_line(chomp: true) do |line|
        key, value = line.split(" ", 2)
        case key
        when "tree"   then @tree = value
        when "parent" then @parent = value
        when "author"
          # "user 2026-11-20T22:00:00+01:00" → name and time.
          # rpartition splits at the LAST space, so names with spaces still work.
          @author, _, @time = value.rpartition(" ")
        end
      end
    end
  end
end