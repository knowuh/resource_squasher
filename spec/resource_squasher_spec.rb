$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.join(File.dirname(__FILE__), "../lib")
require 'resource_squasher'
require 'fakefs/spec_helpers'
include  ResourceSquasher

describe FileEntry do
  before(:each) do
    @base = "/root/directory"
    @old_rez  = "/this/is/a/test.js"
    @file_entry = FileEntry.new(@old_rez,@base)
  end

  it "should know its old path" do
    @file_entry.should respond_to :old_path
    @file_entry.old_path.should == "#{@base}#{@old_rez}"
  end

  it "should keep track of uniqueness" do
    @file_entry.uniq_level.should == 0
    @file_entry.more_uniq.uniq_level.should == 1
    @file_entry.more_uniq.uniq_level.should == 2
  end
  

  it "should calculate unque names" do
    expected_name = "js/00_my_system_test.js"
    @file_entry.name.should == expected_name
    
    exptected_name = "js/01_my_system_test.js"
    @file_entry.more_uniq
    @file_entry.name.should == exptected_name
    
    expected_name = "js/02_my_system_test.js"
    @file_entry.more_uniq
    @file_entry.name.should == expected_name
    
    expected_name = "js/03_my_system_test.js"
    @file_entry.more_uniq
    @file_entry.name.should == expected_name
  end
  
  it "should replace_content" do
    p1 = @file_entry.old_path
    p2 = @file_entry.path
    n1 = @file_entry.old_name
    n2 = @file_entry.name

    test_content = <<-EOF
      "#{p1}" <img src="#{p1}"/> #{n1}
      "#{p2}" <img src="#{p2}"/> #{n1}
      #{p1}#{p1}#{p1}
    EOF
    expected = <<-EOF
      "#{p2}" <img src="#{p2}"/> #{n2}
      "#{p2}" <img src="#{p2}"/> #{n2}
      #{p2}#{p2}#{p2}
    EOF
    @file_entry.replace_content(test_content,{p1=>p2,n1=>n2}).should == expected
  end
end

describe FileMapper do
  include FakeFS::SpecHelpers
  before(:each) do
    @outdir = "/tmp/out"
    @source_dir = "/tmp/build_it"
    @rez_base = "/static"
    # use FakeFS to setup fake files needed
    FileUtils.mkdir_p @outdir
    FileUtils.mkdir_p @source_dir
    @opts = {
      :output_dir => @outdir,
      :source_dir =>  @source_dir,
      :rez_base => @static
    }
    @file_mapper = FileMapper.new(@opts)
  end

  describe "File system changes" do
    it "should create the output directory" do
      File.exist?(@file_mapper.output_dir).should be true
    end
  end


  describe "add_file(resource)" do
    
    it "should throw an exception if the base directory isn't there" do
     lambdafunc = lambda {
      @anohter_mapper = FileMapper.new({
        :old_base => "/nowhere/i/have/been"
      })
     }
     lambdafunc.should raise_error
    end

    it "should not add the same file twice" do
      @file_mapper.add_file("/static/path/to/foo.css")
      @file_mapper.add_file("/static/path/to/foo.css")
      @file_mapper.add_file("/static/path/to/foo.css")
      @file_mapper.old_names.keys.size.should == 1
      @file_mapper.new_names.keys.size.should == 1
    end

    it "should throw exception when trying to add resources that don't start with rez-base" do
      lambda {@file_mapper.add_file("/bad/path/to/foo.css")}.should raise_error
    end
    
    it "should use clever names for similar resources" do
      @file_mapper.add_file("/static/path/to/foo.css")
      @file_mapper.add_file("/static/pathy/to/foo.css")
      @file_mapper.add_file("/static/dir/to/foo.css")
      @file_mapper.old_names.keys.size.should == 3
      @file_mapper.new_names.keys.size.should == 3
      @file_mapper.new_names.values.each do |file| 
        file.path.should match /\/out\//
        file.path.should match /\.css/
        @file_mapper.old_names[file.old_name].should == file
      end
    end
  end
end
describe ResourceSquasher do
  def destroy_tmp_directory
    # this is kinda dangerous but I can't seem to play nicely with FakeFS.
    %x[rm -r tmp/build]
  end

  before(:each) do
    destroy_tmp_directory
    @source_dir = "tmp/build"
    FileUtils.mkdir_p @source_dir
    @rez_base     = "static"
    @project_name = "my_system"
    @opts =  {
      :source_dir   => @source_dir,
      :rez_base     => @rez_base,
      :project_name => @project_name
    }
  end
  describe "project_dir(language)" do
    it "should return the projects build directory" do
      squasher  = ResourceSquasher::ResourceSquasher.new(@opts)
      squasher.project_dir.should match [@source_dir,@rez_base,@project_name,'en'].join("/")
    end
  end
  describe "most_recent_project_html" do
    it "should find a built project when it exists..." do
      build_path = "tmp/build/static/my_system/en/67bd8352e47bfe3a4cabf92df08ef2022c7368a7"
      expected_index = File.join(build_path,"index.html")
      FileUtils.mkdir_p build_path
      File.new(expected_index,"w") # create the index.html file required
      squasher  = ResourceSquasher::ResourceSquasher.new(@opts)
      squasher.most_recent_project_html.should match expected_index
    end

    it "should return the most recent build directory" do
      old_build_path = "tmp/build/static/my_system/en/67bd8352e47bfe3a4cabf92df08ef2022c7368a7"
      new_build_path = "tmp/build/static/my_system/en/67bd8352e47bfe3a4cabf92df08ef2022c7368a8"
      old_index = File.join(old_build_path,"index.html")
      new_index = File.join(new_build_path,"index.html")
      FileUtils.mkdir_p old_build_path
      File.new(old_index,"w") # create the index.html file required
      # ugly! we should mock time
      sleep 0.5
      FileUtils.mkdir_p new_build_path
      File.new(new_index,"w") # create the index.html file required
      squasher  = ResourceSquasher::ResourceSquasher.new(@opts)
      squasher.most_recent_project_html.should match new_index
      squasher.most_recent_project_html.should_not match old_index
    end

    it "should fail when there is no project directory" do
      squasher = ResourceSquasher::ResourceSquasher.new(@opts)
      danger = lambda {
        squasher.most_recent_project_html.should match expected_index
      }
      danger.should raise_error
    end
  end
end

