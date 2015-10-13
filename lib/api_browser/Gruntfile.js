module.exports = function(grunt) {
  // Load grunt tasks automatically
  require('load-grunt-tasks')(grunt);

  // Time how long tasks take. Can help when optimizing build times
  try {
    require('time-grunt')(grunt);
  } catch(e) {

  }

  var userDocsPath = process.env.USER_DOCS_PATH,
      buildPath    = userDocsPath + '/output',
      browserPort  = process.env.DOC_PORT || '9090';

  var cssOutput = {};
  cssOutput[buildPath + '/css/main.css'] = userDocsPath + '/styles.scss';

  grunt.initConfig({
    // web server for development
    connect: {
      options: {
        port: browserPort,
        hostname: '0.0.0.0'
      },
      livereload: {
        options: {
          livereload: 9091,
          open: true,
          base: [
            userDocsPath,
            '.tmp',
            '.data',
            'app'
          ]
        }
      },
      dist: {
        options: {
          base: ['.data', buildPath]
        }
      }
    },

    clean: {
      serve: {
        files: [{
          dot: true,
          src: [
            '.tmp'
          ]
        }]
      },
      dist: {
        options: {
          force: true,
        },
        files: [{
          dot: true,
          src: [
            '.tmp',
            buildPath
          ]
        }]
      }
    },
    // Automatically inject Bower components into the app
    wiredep: {
      app: {
        src: '.tmp/index.html',
        ignorePath: /(..\/)?app\//,
        // We do not use bootstrap's JS code, also the SASS styles are included by our style sheet
        exclude: [/bootstrap-sass/]
      }
    },

    // Automatically inject the JS files into the app
    fileblocks: {
      options: { removeFiles: true },
      dist: {
        src: 'app/index.html',
        dest: '.tmp/index.html',
        blocks: {
          scripts: {
            cwd: 'app',
            // This ensures app.js comes first so the angular module is declared
            src: ['js/app.js', 'js/**/*.js']
          },
          userscripts: {
            // cwd: userDocsPath,
            src: [userDocsPath + '/app.js', userDocsPath + '/**/*.js', '!' + userDocsPath + '/output/**/*.js']
          }
        }
      },

      serve: {
        src: 'app/index.html',
        dest: '.tmp/index.html',
        blocks: {
          scripts: {
            cwd: 'app',
            // This ensures app.js comes first so the angular module is declared
            src: ['js/app.js', 'js/**/*.js']
          },
          userscripts: {
            cwd: userDocsPath,
            src: ['app.js', '**/*.js', '!output/**/*.js']
          }
        }
      }
    },

    // Build stylesheet from SASS files
    sass: {
      server: {
        options: {
          sourceComments: 'map',
          sourceMap: __dirname  + '/.tmp/css/main.css.map',
          includePaths: ['app/sass']
        },
        files: {
          '.tmp/css/main.css': userDocsPath + '/styles.scss'
        }
      },
      dist: {
        options: {
          sourceComments: 'none',
          includePaths: ['app/sass']
        },
        files: cssOutput
      }
    },

    cssmin: {
      dist: {
        files: [{
          src: buildPath + '/css/main.css',
          dest: buildPath + '/css/main.css'
        }]
      }
    },

    ngAnnotate: {
      options: {
        add: true,
        singleQuotes: true,
        ngAnnotateOptions: {
          plugin: [{init: function() {},
          match: function(node) {
            if (node.callee && node.callee.object) {
              var object = node.callee.object;
              if (object && object.type === 'Identifier' && object.name === 'templateForProvider' && node.callee.property.name === 'register') {
                return node.arguments[0];
              }
            }
          }}]
        }
      },
      dist: {
        files: [{
          expand: true,
          cwd: '.tmp/concat/scripts',
          src: '*.js',
          dest: '.tmp/concat/scripts'
        }]
      }
    },

    filerev: {
      dist: {
        src: [
          buildPath + '/scripts/*.js',
          buildPath + '/css/*.css'
        ]
      }
    },

    ngtemplates: {
      options: {
        htmlmin: {
          collapseBooleanAttributes: true,
          collapseWhitespace: true,
          removeAttributeQuotes: true,
          removeComments: true,
          removeEmptyAttributes: true,
          removeRedundantAttributes: true,
          removeScriptTypeAttributes: true,
          removeStyleLinkTypeAttributes: true
        },
        bootstrap: function(module, script) {
          return 'angular.module("' + module + '").run(function($templateCache){' + script + '});';
        },
      },
      dist: {
        cwd: 'app',
        src: 'views/**/*.html',
        dest: '.tmp/templates.js',
        options: {
          usemin: buildPath + '/scripts/praxis.js',
          module: 'PraxisDocBrowser',
        }
      },
      userScripts: {
        cwd: userDocsPath,
        src: 'views/**/*.html',
        dest: '.tmp/usertemplates.js',
        options: {
          usemin: buildPath + '/scripts/docs.js',
          module: 'DocBrowser',
        }
      }
    },

    copy: {
      dist: {
        files: [{
          expand: true,
          dot: true,
          cwd: 'app',
          dest: buildPath,
          src: [
            '*.{ico,png,txt}'
          ]
        }, {
          expand: true,
          dot: true,
          cwd: '.tmp',
          dest: buildPath,
          src: [
            'index.html'
          ]
        }, {
          expand: true,
          dot: true,
          cwd: userDocsPath,
          dest: buildPath,
          src: [
            '**/*',
            '!**/*.{js,scss,sass,less,coffee}',
            '!views/**',
            '!**/.*',
            '!output/**'

          ]
        }]
      }
    },

    // Reads HTML for usemin blocks to enable smart builds that automatically
    // concat, minify and revision files. Creates configurations in memory so
    // additional tasks can operate on them
    useminPrepare: {
      html: '.tmp/index.html',
      options: {
        dest: buildPath
      }
    },

    // Performs rewrites based on rev and the useminPrepare configuration
    usemin: {
      html: [buildPath + '/index.html'],
      css: [buildPath + '/css/{,*/}*.css'],
      options: {
        assetsDirs: [buildPath]
      }
    },

    karma: {
      options: {
        files: [
          'node_modules/quick_check/dist/jasmine-quick-check.js',
          'app/bower_components/jquery/dist/jquery.js',
          'app/bower_components/angular/angular.js',
          'app/bower_components/lodash/lodash.js',
          'app/bower_components/angular-ui-router/release/angular-ui-router.js',
          'app/bower_components/angular-ui-bootstrap-bower/ui-bootstrap-tpls.js',
          'app/bower_components/angular-sanitize/angular-sanitize.js',
          'app/bower_components/angular-mocks/angular-mocks.js',
          'app/bower_components/showdown/compressed/Showdown.min.js',
          'app/js/app.js', 'app/js/**/*.js', '.tmp/templates.js', '../../spec/api_browser/**/*.js'
        ],
        frameworks: ['jasmine'],
        reporters: ['dots'],
      },
      unit: {
        browsers: ['PhantomJS'],
        singleRun: true
      }
    },

    jshint: {
      src: ['app/js/**/*.js', '../../spec/api_browser/**/*.js'],
      options: {
        bitwise: true,
        immed: true,
        newcap: false,
        noarg: true,
        noempty: true,
        nonew: true,
        trailing: true,
        boss: true,
        eqnull: true,
        expr: true,
        laxbreak: true,
        loopfunc: true,
        sub: true,
        undef: true,
        unused: true,
        browser: true,
        quotmark: true,
        indent: 2,
        jasmine: true,
        globals: {
          "angular": false,
          "app": true,
          "_": false,
          "$": false,
          "jQuery": false,
          "Showdown": false,
          "inject": false,
          "qc": false
        }
      }
    }
  });

  grunt.registerTask('inlineJson', function() {
    var data = grunt.file.readJSON(userDocsPath + '/api/index-new.json', {encoding: 'utf8'});
    var result = {};
    data.versions.forEach(function(version) {
      result[version] = grunt.file.readJSON(userDocsPath + '/api/' + version + '.json', {encoding: 'utf8'});
    });
    var source = grunt.file.read(__dirname + '/app/js/factories/Documentation.js', {encoding: 'utf8'});
    source = source.replace(/\/\*\s*REPLACE-WITH-JSON(.|\n)+END-REPLACE\s*\*\//m, JSON.stringify(result, null, 2));
    grunt.file.write(__dirname + '/.tmp/Documentation.js', source, {encoding: 'utf8'});
    var config = grunt.config(['concat', 'generated']);
    var src = config.files[0].src;
    var files = grunt.task.normalizeMultiTaskFiles(config).map(function(files) {
      return files.orig;
    });
    files[1].src.push('{.tmp,app}/Documentation.js');
    grunt.config(['concat', 'generated'], {
      files:    files || grunt.config(['concat', 'generated', 'files']),
      options:  grunt.config(['concat', 'generated', 'options']) || {}
    });
  });

  grunt.registerTask('runGenerator', function() {
    var exec = require('child_process').exec;
    var done = this.async();
    exec('bundle exec rake praxis:docs:experiments', {cwd: userDocsPath + '/../'}, done);
  });

  grunt.registerTask('serve', function(target) {
    if (target === 'dist') {
      return grunt.task.run(['build', 'connect:dist:keepalive']);
    }

    grunt.config.merge({
      watch: {
        // Updates index.html for any file added or removed
        scripts: {
          files: ['app/js/**/*.js', userDocsPath + '/**/*.js'],
          tasks: ['fileblocks:serve', 'wiredep'],
          options: { livereload: 9091 }
        },

        // Updates index.html for any bower component added or removed
        bowerComponents: {
          files: ['app/bower_components/**/*', userDocsPath + '/bower_components/**/*'],
          tasks: 'wiredep',
          options: { livereload: 9091 }
        },

        // Rebuild the stylesheets for any SASS file changed
        sass: {
          files: [
            'app/sass/**/*.scss',
            'app/bower_components/**/*.scss',
            userDocsPath + '/**/*.scss'
          ],
          tasks: 'sass',
          options: { livereload: 9091 }
        },

        data: {
          files: [
            userDocsPath + '/../design/**/*.rb'
          ],
          tasks: 'runGenerator',
          options: { livereload: 9091 }
        },

        // Watches files that don't need processing
        other: {
          files: [
            'app/css/*.css',
            "app/index.html",
            "app/views/**/*.html",
            userDocsPath + '/views/**/*.html'
          ],
          options: {
            livereload: 9091
          }
        }
      }
    });


    grunt.task.run([
      'clean:serve',
      'fileblocks:serve',
      'wiredep',
      'sass:server',
      'connect:livereload',
      'watch'
    ]);
  });

  grunt.registerTask('build', [
    'clean:dist',
    'fileblocks:dist',
    'wiredep',
    'sass:dist',
    'useminPrepare',
    'ngtemplates',
    'inlineJson',
    'concat',
    'ngAnnotate',
    'copy:dist',
    'cssmin',
    'uglify',
    'filerev',
    'usemin'
  ]);

  grunt.registerTask('test', function() {
    grunt.config.set('watch', {
      tests: {
        files: [
          'app/js/**',
          '../../spec/api_browser/**'
        ],
        tasks: ['jshint:src', 'karma:unit'],
        options: {
          atBegin: true
        }
      }
    });

    grunt.task.run([
      'ngtemplates:dist',
      'watch:tests'
    ]);
  });

  grunt.registerTask('ci', [
    'ngtemplates:dist',
    'jshint:src',
    'karma:unit'
  ]);

  grunt.registerTask("default", ["serve"]);
};
