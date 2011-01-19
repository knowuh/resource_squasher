require 'FileUtils'
module ResourceSquasher
  def self.path_to_here
    #realpath = File.expand_path(__FILE__)
    #path,this = File::split(realpath)
    return Dir.getwd
  end
  

  DEFAULT_LANGUAGE     = "en"
  DEFAULT_PROJECT_NAME = "my_system"
  DEFAULT_REZ_BASE     = "static"
  DEFAULT_source_dir   = File.join(self.path_to_here,"tmp","build")
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

    def textfile
      if self.name =~ /[\.html|\.js|\.css|\.txt|\.json|\.htm]$/i
        return true
      end
      return false
    end
    
    def replace_content(content,replacements)
      return content unless self.textfile
      replacements.each_pair do |old,new|
        puts "================================="
        puts "replacing: |#{old}| with |#{new}|"
        puts "================================="
        content.gsub!(old,new)
      end
      return content
    end

    def resave(replacements={})
      old_content = File.read(self.old_path)
      content = replace_content(old_content,replacements)
      FileUtils.mkdir_p(File.dirname(self.new_path))
      puts self.new_path
      File.open(self.new_path, "w") do |f|
        f.write(content)
      end
    end


    def join_char
      "_"
    end
    
    def self.match_types
      {
        /\.jpg|png|gif$/i => 'images',
        /\.js|json$/i     => 'js',
        /\.css$/i         => 'css',
      }
    end
    
    def prefix
      FileEntry::match_types.each_pair do |regex,result|
        if self.old_name =~ regex
          return result
        end
      end
      return ""
    end

    def rename
      path_parts = self.old_name.split(File::SEPARATOR)
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
      unless self.prefix.empty?
        self.name = [self.prefix,self.name].join(File::SEPARATOR)
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
    attr_accessor :rez_base
    attr_accessor :source_dir
    attr_accessor :output_dir


    def initialize(opts = {})
      self.old_names   = {}
      self.new_names   = {}
      self.rez_base    = opts[:rez_base]   || DEFAULT_REZ_BASE
      self.output_dir  = opts[:output_dir] || DEFAULT_OUTPUT_DIR
      self.source_dir  = opts[:source_dir] || DEFAULT_source_dir

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
  
  class ResourceSquasher
    attr_accessor :source_dir
    attr_accessor :project_name
    attr_accessor :rez_base
    attr_accessor :file_mapper
    attr_accessor :output_dir

    def initialize(_opts={})
      defaults = {
        :source_dir   => DEFAULT_source_dir,
        :project_name => DEFAULT_PROJECT_NAME,
        :output_dir   => DEFAULT_OUTPUT_DIR,
        :rez_base     => DEFAULT_REZ_BASE
      }
      opts              = defaults.merge(_opts)
      self.output_dir   = opts[:output_dir]
      self.source_dir   = opts[:source_dir]
      self.project_name = opts[:project_name]
      self.rez_base     = opts[:rez_base]
      self.file_mapper  = FileMapper.new(opts)
    end

    def project_dir(lang = "en")
      File.join(self.source_dir,self.rez_base,self.project_name,lang)
    end
    
    #  tmp/build/static/my_system/en/67bd8352e47bfe3a4cabf92df08ef2022c7368a7/
    def most_recent_project_html
      matching = /[a-z|0-9]{40}/ #TODO: This signature is only valid against sproutcore builds.
      parent_dir = Dir.new(project_dir)
      builds = parent_dir.entries.collect { |file| File.new(File.join(parent_dir.path,file)) }.sort { |file1,file2| file1.mtime <=> file2.mtime }
      builds.reject! { |file| ((file.path =~ matching) ? false : true) }
      return File.join(builds.last,"index.html")
    end

    def resource_regex
      /['|"]\s*(\/#{self.rez_base}\/[^"|^']*)['|"]/
    end

    def match_resources(txt)
      return txt.match resource_regex
    end

    def load_all
      html_path = self.most_recent_project_html
      html_resource = html_path.gsub(self.source_dir,"")
      self.file_mapper.add_file(html_resource)
      load_resources(html_path)
    end

    def load_resources(filename)
      puts "loading resources from #{filename}"
      file = File.new(filename)
      content = file.read
      content.scan(resource_regex) do  |mgroup|
        resource = mgroup.first
        #TODO: return value for add_file is true if new file
        # and adding was successful
        puts "adding resource #{resource}"
        if self.file_mapper.add_file(resource)
          added_file = self.file_mapper.old_names[resource]
          if resource =~ /[\.html|\.js|\.css|\.txt|\.json|\.htm]$/i
            puts "next file: #{added_file.old_path}"
            self.load_resources(added_file.old_path)
          end
        else
          puts "resource #{resource} has already been mapped"
        end
      end
    end

    def rewrite_resources
      replacements = {}
      self.file_mapper.new_names.values.each do |record|
        replacements[record.old_name] = record.name
      end
      self.file_mapper.new_names.values.each do |record|
        puts "--------------------------------------------------"
        record.resave(replacements)
      end
    end

  end
end
