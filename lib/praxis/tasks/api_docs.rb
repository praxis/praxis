namespace :praxis do

  namespace :docs do
    path = File.expand_path(File.join(File.dirname(__FILE__), '../../api_browser'))

    desc "Install dependencies"
    task :install do
      unless system("npm install", chdir: path)
        raise Exception.new("NPM Install Failed")
      end

      docs_dir=File.join(Dir.pwd, 'docs')
      FileUtils.mkdir_p docs_dir unless File.directory? docs_dir

      # The doc browser will need to have a minimal app.js and styles.css file at the root
      # Let's add them if the app has not overriden them 
      js_file = File.join(Dir.pwd, 'docs', 'app.js') 
      scss_file = File.join(Dir.pwd, 'docs', 'styles.scss')   
      unless File.exists? js_file
        File.open(js_file, 'w') {|f| f.write(%q{angular.module('DocBrowser', ['PraxisDocBrowser']);}) }
      end
      unless File.exists? scss_file
        File.open(scss_file, 'w') {|f| f.write(%q{@import "praxis.scss";}) }
      end

    end

    desc "Run API Documentation Browser"
    task :preview => [:install, :api_docs] do
      exec({'USER_DOCS_PATH' => File.join(Dir.pwd, 'docs')}, "#{path}/node_modules/.bin/grunt serve --gruntfile '#{path}/Gruntfile.js'")
    end

    desc "Build docs that can be shipped"
    task :build => [:install, :api_docs] do
      exec({'USER_DOCS_PATH' => File.join(Dir.pwd, 'docs')}, "#{path}/node_modules/.bin/grunt build --gruntfile '#{path}/Gruntfile.js'")
    end

    desc "Generate API docs (JSON definitions) for a Praxis App"
    task :generate => [:environment] do |t, args|
      require 'fileutils'

      Praxis::Blueprint.caching_enabled = false
      generator = Praxis::RestfulDocGenerator.new(Dir.pwd)
    end

  end

  desc "Generate API docs (JSON definitions) for a Praxis App"
  task :api_docs => ['docs:generate']

  desc "Run API Documentation Browser"
  task :doc_browser, [:port] => :api_docs do |t, args|
    args.with_defaults port: 4567

    public_folder =  File.expand_path("../../../", __FILE__) + "/api_browser/app"
    app = Rack::Builder.new do
      map "/docs" do # application JSON docs
        use Rack::Static, urls: [""], root: File.join(Dir.pwd, Praxis::RestfulDocGenerator::API_DOCS_DIRNAME)
      end
      map "/" do # Assets mapping
        use Rack::Static, urls: [""], root: public_folder, index: "index.html"
      end

      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, ['Not Found']] }
    end


    Rack::Server.start app: app, Port: args[:port]
  end

end
