module ResourceSquasher
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
end
