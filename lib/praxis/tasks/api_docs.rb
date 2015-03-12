namespace :praxis do

  namespace :docs do
    path = File.expand_path(File.join(File.dirname(__FILE__), '../../api_browser'))

    desc "Install dependencies"
    task :install do
      unless system("npm install --production", chdir: path)
        raise Exception.new("NPM Install Failed")
      end

      docs_dir = File.join(Dir.pwd, 'docs')
      FileUtils.mkdir_p docs_dir unless File.directory? docs_dir

      # The doc browser will need to have a minimal app.js and styles.css file at the root
      # Let's add them if the app has not overriden them
      js_file = File.join(Dir.pwd, 'docs', 'app.js')
      scss_file = File.join(Dir.pwd, 'docs', 'styles.scss')
      template_directory = File.expand_path(File.join(File.dirname(__FILE__), '../../../tasks/thor/templates/generator/empty_app/docs'))

      unless File.exists? js_file
        FileUtils.cp File.join(template_directory, 'app.js'), js_file
      end
      unless File.exists? scss_file
        FileUtils.cp File.join(template_directory, 'styles.scss'), scss_file
      end
    end

    desc "Run API Documentation Browser"
    task :preview, [:port] => [:install, 'docs:generate']  do |t, args|      
      doc_port = args[:port] || '9090'
      exec({'USER_DOCS_PATH' => File.join(Dir.pwd, 'docs'), 'DOC_PORT' => doc_port}, "#{path}/node_modules/.bin/grunt serve --gruntfile '#{path}/Gruntfile.js'")
    end

    desc "Build docs that can be shipped"
    task :build => [:install, 'docs:generate'] do
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
  task :api_docs do
    STDERR.puts "DEPRECATION: praxis:api_docs is deprecated and will be removed by 1.0. Please use praxis:docs:generate instead."
    Rake::Task["praxis:docs:generate"].invoke
  end

  desc "Run API Documentation Browser"
  task :doc_browser, [:port] do |t, args|
    STDERR.puts "DEPRECATION: praxis:doc_browser is deprecated and will be removed by 1.0. Please use praxis:docs:preview instead. The doc browser now runs on port 9090."
    Rake::Task["praxis:docs:preview"].invoke
  end

end
