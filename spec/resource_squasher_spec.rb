$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.join(File.dirname(__FILE__), "../lib"
#$LOAD_PATH << File.join(File.dirname(__FILE__), "helpers"

require 'resource_squasher'
require 'fakefs/spec_helpers'
#require 'fakefs_mods'

describe ResourceSquasher::FileEntry do
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
    expected_name = "00_root_test.js"
    @file_entry.name.should == expected_name
    
    exptected_name = "00_root_a_test.js"
    @file_entry.more_uniq
    @file_entry.name.should == exptected_name
    
    expected_name = "00_root_is_a_test.js"
    @file_entry.more_uniq
    @file_entry.name.should == expected_name
    
    expected_name = "00_root_this_is_a_test.js"
    @file_entry.more_uniq
    @file_entry.name.should == expected_name
    
    expected_name = "00_root_directory_this_is_a_test.js"
    @file_entry.more_uniq
    @file_entry.name.should == expected_name
    
    expected_name = "01_root_directory_this_is_a_test.js"
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
    @file_entry.replace_content(test_content).should == expected
  end
end

describe ResourceSquasher::FileMapper do
  include FakeFS::SpecHelpers
  before(:each) do
    @outdir = "/tmp/out"
    @build_dir = "/tmp/build_it"
    @rez_base = "/static"
    # use FakeFS to setup fake files needed
    FileUtils.mkdir_p @outdir
    FileUtils.mkdir_p @build_dir
    @opts = {
      :output_dir => @outdir,
      :build_dir =>  @build_dir,
      :rez_base => @static
    }
    @file_mapper = FileMapper.new(@opts)
  end

  describe "File system changes" do
    it "should create the output directory" do
      File.exist?(@file_mapper.output_dir).should be true
    end
  end

  describe "output_dir_for(resource)" do
    it "should return #{@outdir}/images for images" do
      @file_mapper.output_dir_for("/static/thing/big/foo.jpg").should == "#{@outdir}/images"
      @file_mapper.output_dir_for("/static/thing/big/foo.gif").should == "#{@outdir}/images"
      @file_mapper.output_dir_for("/static/thing/big/foo.png").should == "#{@outdir}/images"
    end
    it "should return #{@outdir}/js for javascript" do
      @file_mapper.output_dir_for("/static/thing/big/foo.js").should == "#{@outdir}/js"
      @file_mapper.output_dir_for("/static/thing/big/foo.json").should == "#{@outdir}/js"
    end
    it "should return #{@outdir}/html for html" do
      @file_mapper.output_dir_for("/static/thing/big/foo.html").should == "#{@outdir}/html"
    end
    it "should return #{@outdir}/css for css" do
      @file_mapper.output_dir_for("/static/thing/big/foo.css").should == "#{@outdir}/css"
    end
    it "should return /out for misc files" do
      @file_mapper.output_dir_for("/static/thing/big/foo.txt").should == "#{@outdir}"
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

