module ResourceSquasher
  class FileMapper
    attr_accessor :old_names
    attr_accessor :new_names
    attr_accessor :rez_base
    attr_accessor :source_dir
    attr_accessor :output_dir

    def initialize(opts = {})
      self.old_names   = {}
      self.new_names   = {}
      self.rez_base    = opts[:rez_base]   || DEFAULT_REZ_BASE
      self.output_dir  = opts[:output_dir] || DEFAULT_OUTPUT_DIR
      self.source_dir  = opts[:source_dir] || DEFAULT_SOURCE_DIR
      raise "can't find the source directory #{self.source_dir}" unless File.exists?(self.source_dir)
      self.create_output_dir
    end

    def create_output_dir
      begin
        unless File.exist?(self.output_dir)
          FileUtils.mkdir_p(self.output_dir)
        end
      rescue
        throw "Couldn't create output directory #{self.output_dir}"
      end
    end

    def add_file(_rez)
      raise "Cant add #{_rez} -- not routed in #{self.rez_base}" unless (_rez =~ /#{self.rez_base}/)
      newEntry = FileEntry.new(_rez,self.source_dir,self.output_dir)
      # skip it if we already have it
      unless self.old_names.has_key?(newEntry.old_name)
        while (self.new_names.has_key?(newEntry.name))
          newEntry.more_uniq
        end
        self.new_names[newEntry.name] = newEntry
        self.old_names[newEntry.old_name] = newEntry
        return true
      end
      return false #we didn't actually add it, because it was there.
    end
  end
end
