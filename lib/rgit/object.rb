# Shared helper: stores any content (blob, tree or commit) in .rgit/objects
require "digest" # SHA-1 hashing
require "zlib" # Compression
require "fileutils" # mkdir_p

module RGit
  class Object
    RGIT_DIRECTORY = File.join(Dir.pwd, ".rgit")
    OBJECT_DIRECTORY = File.join(RGIT_DIRECTORY, "objects")

    # Hashes the content, saves it compressed, and return the hash
    # Same content means same hash, so storing it twice just overwrites
    # an identical file
    def self.write(content)
      sha = Digest::SHA1.hexdigest(content)
      
      directory = File.join(OBJECT_DIRECTORY, sha[0..1])
      FileUtils.mkdir_p(directory)
      File.binwrite(File.join(directory, sha[2..]), Zlib::Deflate.deflate(content))

      sha
    end

    # Reads an object back and decompresses it (used by cat-file)
    def self.read(sha)
      path = File.join(OBJECT_DIRECTORY, sha[0..1], sha[2..])
      Zlib::Inflate.inflate(File.binread(path))
    end
  end
end