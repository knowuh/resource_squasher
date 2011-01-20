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
end
require 'resource_squasher/file_entry'
require 'resource_squasher/file_mapper'
require 'resource_squasher/resource_squasher'
