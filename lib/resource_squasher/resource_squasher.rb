#require 'resource_squasher/file_mapper'

module ResourceSquasher
  class ResourceSquasher
    attr_accessor :source_dir
    attr_accessor :rez_base
    attr_accessor :file_mapper
    attr_accessor :output_dir
    attr_accessor :index_name
    attr_accessor :language
    attr_accessor :build_number

    def self.initialize
      @project_name = nil
    end
    
    def self.project_name=(new_name)
      if new_name
        @project_name = new_name
      end
    end

    def self.project_name
      unless @project_name
        @project_name = ResourceSquasher::DEFAULT_PROJECT_NAME
      end
      return @project_name
    end

    def self.squash_sproutcore_app(opts={})
      squasher = ResourceSquasher.new(opts)
      squasher.load_all
      squasher.rewrite_resources
    end

    def initialize(_opts={})
      defaults = {
        :source_dir   => DEFAULT_SOURCE_DIR,
        :project_name => DEFAULT_PROJECT_NAME,
        :output_dir   => DEFAULT_OUTPUT_DIR,
        :rez_base     => DEFAULT_REZ_BASE
      }
      opts                          = defaults.merge(_opts)
      ResourceSquasher.project_name = opts[:project_name]
      self.output_dir               = opts[:output_dir]
      self.source_dir               = opts[:source_dir]
      self.rez_base                 = opts[:rez_base]
      self.language                 = opts[:language]
      self.index_name               = opts[:index_name]
      self.build_number             = `sc-build-number #{ResourceSquasher.project_name}`
      self.file_mapper              = FileMapper.new(opts)
    end

    # find the build directory for the sproutcore project self.project_name
    def project_dir(lang = "en")
      File.join(self.source_dir,self.rez_base,ResourceSquasher.project_name,lang)
    end

    #  tmp/build/static/my_system/en/67bd8352e47bfe3a4cabf92df08ef2022c7368a7/
    def most_recent_project_html
      matching = /#{self.build_number}/ #TODO: This signature is only valid against sproutcore builds.
      parent_dir = Dir.new(project_dir)
      builds = parent_dir.entries.collect { |file| File.new(File.join(parent_dir.path,file)) }.sort { |file1,file2| file1.mtime <=> file2.mtime }
      builds.reject! { |file| ((file.path =~ matching) ? false : true) }
      return File.join(builds.last,"index.html")
    end

    # regex for resources which can be replaced
    def resource_regex
      /(?:['|"]|&quot;)\s*(\/#{self.rez_base}\/.*?)(?:['|"]|&quot;)/
    end

    # load resources, starting with index.html in the 
    # sproutcore application defined by self.project_name
    def load_all
      html_path = self.most_recent_project_html
      html_resource = html_path.gsub(self.source_dir,"")
      self.file_mapper.add_file(html_resource, "#{self.index_name}.html")
      load_resources(html_path)
    end

    # Recursively load resources found in filename
    def load_resources(filename)
      file = File.new(filename)
      content = file.read
      file.close
         
      # replace 'static/my_system/en/current/' => 'static/my_system/en/fe766a8e4c82f8b387effb309563f4fd114248ee/' 
      # (where fe766... is current build number)
      
      content.gsub!(/#{self.rez_base}\/#{ResourceSquasher.project_name}\/#{self.language}\/current\//, "#{self.rez_base}/#{ResourceSquasher.project_name}/#{self.language}/#{self.build_number}/")

      out = File.new(filename, 'w')
      out.write(content)
      out.close
      
      content.scan(resource_regex) do  |mgroup|
        resource = mgroup.first
        #TODO: return value for add_file is true if new file
        # and adding was successful
        if self.file_mapper.add_file(resource)
          added_file = self.file_mapper.old_names[resource]
          if resource =~ /[\.html|\.js|\.css|\.txt|\.json|\.htm]$/i
            self.load_resources(added_file.old_path)
          end
        else
        end
      end
    end

    # rewrite the resource references in files, using new shorter names
    def rewrite_resources
      replacements = {}
      self.file_mapper.new_names.values.each do |record|
        replacements[record.old_name] = record.name
      end
      self.file_mapper.new_names.values.each do |record|
        record.resave(replacements)
      end
    end
  end
end
