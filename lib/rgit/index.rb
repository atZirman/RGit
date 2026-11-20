# The staging area: which path currently has which content (sha).
# Entries stay after a commit, so every commit is a full snapshot.
module RGit
  class Index
    PATH = File.join(Dir.pwd, ".rgit", "index")

    # Returns a hash like { "hello.txt" => "<sha>", "src/app.rb" => "<sha>" }
    def self.load
      return {} unless File.exist?(PATH)

      File.readlines(PATH, chomp: true).reject(&:empty?).to_h do |line|
        sha, path = line.split(" ", 2)  # split on the first space only
        [path, sha]
      end
    end

    # Rewrites the whole index, sorted by path (real git sorts it too)
    def self.save(entries)
      lines = entries.sort.map { |path, sha| "#{sha} #{path}\n" }
      File.write(PATH, lines.join)
    end
  end
end