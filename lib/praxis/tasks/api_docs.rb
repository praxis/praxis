namespace :praxis do

  namespace :docs do

    def base_path
      require 'uri'
      documentation_url = Praxis::ApiDefinition.instance.global_info.documentation_url
      URI(documentation_url).path.gsub(/\/[^\/]*$/, '/') if documentation_url
    end

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
    task :preview, [:port] => [:install, :generate]  do |t, args|
      doc_port = args[:port] || '9090'
      exec({
        'USER_DOCS_PATH' => File.join(Dir.pwd, 'docs'),
        'DOC_PORT' => doc_port,
        'PLUGIN_PATHS' => Praxis::Application.instance.doc_browser_plugin_paths.join(':'),
        'BASE_PATH' => '/'
      }, "#{path}/node_modules/.bin/grunt serve --gruntfile '#{path}/Gruntfile.js'")
    end

    desc "Build docs that can be shipped"
    task :build => [:install, :generate] do
      exec({
        'USER_DOCS_PATH' => File.join(Dir.pwd, 'docs'),
        'PLUGIN_PATHS' => Praxis::Application.instance.doc_browser_plugin_paths.join(':'),
        'BASE_PATH' => base_path
      }, "#{path}/node_modules/.bin/grunt build --gruntfile '#{path}/Gruntfile.js'")
    end

    desc "Generate API docs (JSON definitions) for a Praxis App"
    task :generate => [:environment] do |t, args|
      require 'fileutils'

      Praxis::Blueprint.caching_enabled = false
      generator = Praxis::Docs::Generator.new(Dir.pwd)
      generator.save!
    end

  end
end
