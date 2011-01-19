module ResourceSquasher
  def self.path_to_here
    realpath = File.expand_path(__FILE__)
    path,this = File::split(realpath)
    return path
  end
  

  DEFAULT_LANGUAGE     = "en"
  DEFAULT_PROJECT_NAME = "my_system"
  DEFAULT_REZ_BASE     = "static"
  DEFAULT_BUILD_DIR    = File.join(self.path_to_here,"tmp","build")
  DEFAULT_OUTPUT_DIR   = File.join(self.path_to_here,"tmp", "squashed_build")


  class FileEntry
    attr_accessor :old_base
    attr_accessor :base
    attr_accessor :old_name
    attr_accessor :name
    attr_accessor :uniq_level
    def initialize(_rez_path,_old_base,_new_base="/tmp")
      self.old_name = _rez_path
      self.old_base = _old_base
      self.base = _new_base
      self.uniq_level = 0
      self.rename
    end

    def old_path
      "#{self.old_base}#{self.old_name}"
    end

    def new_path
      "#{self.base}/#{self.name}"
    end
    alias path new_path

    def replace_content(content)
      _old_path = self.old_path
      _new_path = self.new_path
      replacements = {
        _old_path => _new_path,
        self.old_name => self.name
      }
      replacements.each_pair do |old,new|
        content.gsub!(old,new)
      end
      content
    end

    def resave(base,replacements)
      content = replace_content(File.read(old_path),replacements)
      File.new(new_path(base), "w") do |f|
        f.write(content)
      end
    end

    def join_char
      "_"
    end

    def rename
      path_parts = self.old_path.split(File::SEPARATOR)
      blank = path_parts.shift # leading slash
      base = path_parts.shift
      name = path_parts.pop
      n_format = "%02d"
      remainder = 0
      remainder = path_parts.size - self.uniq_level
      remainder = remainder * -1
      remainder = remainder < 0 ? 0 : remainder
      last_index = path_parts.size
      start_index= last_index - self.uniq_level
      start_index = start_index < 0 ? 0 : start_index
      middle = path_parts[start_index...last_index]
      if middle && middle.size > 0
        middle = middle.join(self.join_char)
        self.name = [n_format % remainder,base,middle,name].join(self.join_char)
      else
        self.name = [n_format % remainder,base,name].join(self.join_char)
      end
    end

    # our filename isn't uniq enough yet.
    def more_uniq
      self.uniq_level += 1
      self.rename
      self
    end
  end

  class FileMapper
    attr_accessor :old_names
    attr_accessor :new_names
    attr_accessor :rez_output_dir
    attr_accessor :build_dir
    attr_accessor :output_dir
    attr_accessor :match_types

    def self.default_match_tpyes
      {
        /\.jpg|png|gif$/i => 'images',
        /\.html$/i        => 'html',
        /\.js|json$/i     => 'js',
        /\.css$/i         => 'css',
      }
    end

    def initialize(opts = {})
      self.old_names      = {}
      self.new_names      = {}
      self.rez_output_dir = opts[:rez_output_dir] || DEFAULT_REZ_BASE
      self.output_dir     = opts[:output_dir]     || DEFAULT_OUTPUT_DIR
      self.build_dir      = opts[:build_dir]      || DEFAULT_BUILD_DIR
      self.match_types    = FileMapper.default_match_tpyes.merge!(opts[:match_types] || {})

      raise "can't find the ouput directory #{self.build_dir}" unless File.exists?(self.build_dir)
      self.create_output_dir
    end

    def create_output_dir
      begin
        FileUtils.mkdir_p(self.output_dir) 
      rescue
        throw "Couldn't create output directory #{self.output_dir}"
      end
    end

    def output_dir_for(_rez)
      self.match_types.each_pair do |regex,result|
        if _rez =~ regex
          return "#{self.output_dir}/#{result}"
        end
      end
      return self.output_dir
    end

    def add_file(_rez)
      raise "Cant add #{_rez} -- not routed in #{self.rez_output_dir}" unless _rez =~ /#{self.rez_output_dir}/
      newEntry = FileEntry.new(_rez,self.build_dir,self.output_dir_for(_rez))
      # skip it if we already have it
      unless self.old_names.has_key?(newEntry.old_name)
        while (self.new_names.has_key?(newEntry.name))
          newEntry.more_uniq
        end
        self.new_names[newEntry.name] = newEntry
        self.old_names[newEntry.old_name] = newEntry
      end
    end
  end

  class ResourceSquasher
    attr_accessor :build_dir
    attr_accessor :project_name
    attr_accessor :soure_html
    attr_reader   :file_mapper

    def initialize(_opts={})
      defaults = {
        :build_dir      => DEFAULT_BUILD_DIR,
        :project_name   => DEFAULT_PROJECT_NAME,
        :output_dir     => DEFAULT_OUTPUT_DIR
      }
      self.file_mapper = FileMapper.new(opts)
      self.build_dir = opts[:build_dir] || DEFAULT_BUILD_DIR
      self.project_name = opts[:project_name] || DEFAULT_PROJECT_NAME
    end

    #  tmp/build/static/my_system/en/67bd8352e47bfe3a4cabf92df08ef2022c7368a7/
    def most_recent_project_dir
      parent_dir = Dir.new()
      files = self.entries.collect { |file| self+file }.sort { |file1,file2| file1.mtime <=> file2.mtime }
      files.reject! { |file| ((file.file? and file.to_s =~ matching) ? false : true) }
      files.last
    end
  end
end
