namespace :praxis do

  namespace :docs do

    desc "Generate OpenAPI 3 docs for a Praxis App"
    task :generate => [:environment] do |t, args|
      require 'fileutils'

      Praxis::Blueprint.caching_enabled = false
      generator = Praxis::Docs::OpenApiGenerator.instance
      generator.configure_root(Dir.pwd)
      generator.save!
    end

    desc "Preview (and Generate) OpenAPI 3 docs for a Praxis App"
    task :preview => [:generate] do |t, args|
      require 'webrick' 
      docs_port = 9090
      root = Dir.pwd + '/docs/openapi/'
      wb = Thread.new do
        s = WEBrick::HTTPServer.new(:Port => docs_port, :DocumentRoot => root)
        trap('INT') { s.shutdown }
        s.start
      end
      # If there is only 1 version we'll feature it and open the browser onto it
      versions = Dir.children(root)
      featured_version = (versions.size < 2) ? "#{versions.first}/" : ''
      `open http://localhost:#{docs_port}/#{featured_version}`
      wb.join
    end
    desc "Generate and package all OpenApi Docs into a zip, ready for a Web server (like S3...) to present it"
    task :package => [:generate] do |t, args|
      docs_root = Dir.pwd + '/docs/openapi/'
      zip_file = Dir.pwd + '/docs/openapi.zip'
      `rm -f #{zip_file}`
      # NOTE: This assumes the "zip" utility is installed, supporting the recursive flag.
      `zip -r #{zip_file} #{docs_root}`
      puts
      puts "Left packaged API docs in #{zip_file}"
      puts " --> To view the docs, unzip the file under a web server (or S3...) and access the index.hml files from a browser"
    end
  end
end
