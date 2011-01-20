
## Resource Squasher

Flattens and simplifies sproutcore builds, using relative links
between nested resources. This project is distributed
under the MIT License, see the file "LICENSE" in this directory.

Requirements:

* bundler

bundler should take of the rest.

Building:
    bundle install
    rake build

Intalling:
    rake install

or if you just have the gemfile somewhere:
    gem install /path/togemfile/resource_squasher-x.x.x.gem


Using:
      rezsquish squash [PROJECT_NAME]

    Options:
      [--source-dir=SOURCE_DIR]      
                                     # Default: /Users/npaessel/.rvm/tmp/build
      [--output-dir=OUTPUT_DIR]      
                                     # Default: /Users/npaessel/.rvm/tmp/squashed
      [--rez-base=REZ_BASE]          
                                     # Default: static
      [--project-name=PROJECT_NAME]  
                                     # Default: my_system

eg:
    rezsquish squash --project_name=my_app --output_dir=built


TODO:
    remove default project name, and ask for project name instead.



## Running tets (use bundler)

You can run tests, they depend on FakeFS. Bundler can help you, but you
need to do it this way:

    bundle exec rspec ./spec/*_spec.rb

