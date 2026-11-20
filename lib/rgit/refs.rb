# Everything about HEAD and branches
module RGit
  module Refs
    RGIT_DIRECTORY = File.join(Dir.pwd, ".rgit")
    HEAD_PATH      = File.join(RGIT_DIRECTORY, "HEAD")

    # The ref HEAD points to, e.g. "refs/heads/master"
    def self.current_ref
      File.read(HEAD_PATH).strip.delete_prefix("ref: ")
    end

    # Just the branch name, e.g. "master"
    def self.current_branch
      current_ref.split("/").last
    end

    # The sha of the latest commit, or nil before the first commit
    def self.head_commit
      path = File.join(RGIT_DIRECTORY, current_ref)
      File.exist?(path) ? File.read(path).strip : nil
    end

    # Moves the current branch to a new commit
    def self.update_head(commit_sha)
      File.write(File.join(RGIT_DIRECTORY, current_ref), commit_sha + "\n")
    end
  end
end