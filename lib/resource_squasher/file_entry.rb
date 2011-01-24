module ResourceSquasher
  class FileEntry
    attr_accessor :old_base
    attr_accessor :base
    attr_accessor :old_name
    attr_accessor :name
    attr_accessor :uniq_level
    attr_accessor :name_root
    def initialize(_rez_path,_old_base,_name_root=nil,_new_base="/tmp")
      self.old_name = _rez_path
      self.old_base = _old_base
      self.base = _new_base
      self.uniq_level = 0
      unless _name_root
        _name_root = File.basemame(_rez_path)
      end
      self.rename
    end

    def old_path
      "#{self.old_base}#{self.old_name}"
    end

    def new_path
      "#{self.base}/#{self.name}"
    end
    alias path new_path

    def textfile?
      if self.name =~ /[\.html|\.js|\.css|\.txt|\.json|\.htm]$/i
        return true
      end
      return false
    end

    def replace_content(content,replacements)
      return content unless self.textfile?
      replacements.each_pair do |old,new|
        content.gsub!(old,new)
      end
      return content
    end

    def resave(replacements={})
      old_content = File.read(self.old_path)
      content = replace_content(old_content,replacements)
      FileUtils.mkdir_p(File.dirname(self.new_path))
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
      n_format = "%02d"
      name = self.name_root
      self.name = [n_format % self.uniq_level,name].join(self.join_char)
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
end
