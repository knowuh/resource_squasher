# monkypatch a missing feature in file
module FakeFS
  class File < StringIO
    def self.split(path)
      return RealFile.split(path)
    end
  end
end
