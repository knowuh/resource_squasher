module ResourceSquasher
  def self.path_to_here
    return Dir.getwd
  end

  DEFAULT_LANGUAGE     = "en"
  DEFAULT_PROJECT_NAME = "my_system"
  DEFAULT_INDEX_NAME   = "mysystem_sc"
  DEFAULT_REZ_BASE     = "static"
  DEFAULT_SOURCE_DIR   = File.join(self.path_to_here,"tmp", "build")
  DEFAULT_OUTPUT_DIR   = File.join(self.path_to_here,"tmp", "squashed")
  
end
require 'resource_squasher/file_entry'
require 'resource_squasher/file_mapper'
require 'resource_squasher/resource_squasher'
