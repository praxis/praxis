module.exports = function(grunt) {
  // Load grunt tasks automatically
  require('load-grunt-tasks')(grunt);

  // Time how long tasks take. Can help when optimizing build times
  require('time-grunt')(grunt);

  grunt.initConfig({
    // web server for development
    connect: {
      options: {
        port: '9090',
        hostname: '0.0.0.0'
      },
      livereload: {
        options: {
          livereload: 9091,
          open: true,
          base: [
            '.tmp',
            '.data',
            'app'
          ]
        }
      },
      dist: {
        options: {
          base: ['.data', 'dist']
        }
      }
    },

    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
            'dist/*',
            '!dist/.git*'
          ]
        }]
      }
    },

    // Watches files for changes
    watch: {
      // Reload stuff when the grunt file changes
      config: {
        files: ['Gruntfile.js'],
        tasks: 'prep',
        options: {
          reload: true
        }
      },

      // Updates index.html for any file added or removed
      scripts: {
        files: ['app/js/**/*.js'],
        tasks: 'fileblocks:scripts',
        options: { livereload: 9091 }
      },

      // Updates index.html for any bower component added or removed
      bowerComponents: {
        files: ['app/bower_components/**/*'],
        tasks: 'wiredep',
        options: { livereload: 9091 }
      },

      // Rebuild the stylesheets for any SASS file changed
      sass: {
        files: [
          'app/sass/**/*.scss',
          'app/bower_components/**/*.scss'
        ],
        tasks: 'sass',
        options: { livereload: 9091 }
      },

      // Watches files that don't need processing
      other: {
        files: [
          'app/css/*.css',
          "app/index.html",
          "app/views/**/*.html"
        ],
        options: {
          livereload: 9091
        }
      }
    },

    // Automatically inject Bower components into the app
    wiredep: {
      app: {
        src: 'app/index.html',
        ignorePath: 'app/',
        // We do not use bootstrap's JS code, also the SASS styles are included by our style sheet
        exclude: [/bootstrap-sass/]
      }
    },

    // Automatically inject the JS files into the app
    fileblocks: {
      options: { removeFiles: true },
      scripts: {
        src: 'app/index.html',
        blocks: {
          scripts: {
            cwd: 'app',
            // This ensures app.js comes first so the angular module is declared
            src: ['js/app.js', 'js/**/*.js']
          }
        }
      }
    },

    // Build stylesheet from SASS files
    sass: {
      server: {
        options: {
          sourceComments: 'map',
          sourceMap: 'app/css/main.css.map'
        },
        files: {
          'app/css/main.css': 'app/sass/main.scss'
        }
      },
      dist: {
        options: {
          sourceComments: 'none'
        },
        files: {
          'dist/css/main.css': 'app/sass/main.scss'
        }
      }
    },

    cssmin: {
      dist: {
        files: {
          'dist/css/main.css': [
            'dist/css/main.css'
          ]
        }
      }
    },

    ngmin: {
      dist: {
        files: [{
          expand: true,
          cwd: '.tmp/concat/scripts',
          src: 'scripts.js',
          dest: '.tmp/concat/scripts'
        }]
      }
    },

    filerev: {
      dist: {
        src: [
          'dist/scripts/*.js',
          'dist/css/*.css'
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
        module: 'docBrowser',
        bootstrap: function(module, script) {
          return 'angular.module("' + module + '").run(function($templateCache){' + script + '});';
        },
        usemin: 'dist/scripts/scripts.js'
      },
      dist: {
        cwd: 'app',
        src: 'views/**/*.html',
        dest: '.tmp/templates.js'
      }
    },

    copy: {
      dist: {
        files: [{
          expand: true,
          dot: true,
          cwd: 'app',
          dest: 'dist',
          src: [
            '*.{ico,png,txt}',
            'index.html',
          ]
        }]
      }
    },

    // Reads HTML for usemin blocks to enable smart builds that automatically
    // concat, minify and revision files. Creates configurations in memory so
    // additional tasks can operate on them
    useminPrepare: {
      html: 'app/index.html',
      options: {
        dest: 'dist'
      }
    },

    // Performs rewrites based on rev and the useminPrepare configuration
    usemin: {
      html: ['dist/{,*/}*.html'],
      css: ['dist/css/{,*/}*.css'],
      options: {
        assetsDirs: ['dist']
      }
    }
  });

  // Prepares the assets (used by watch:config)
  grunt.registerTask('prep', [
      'fileblocks',
      'wiredep',
      'sass'
  ]);

  grunt.registerTask('serve', function(target) {
    if (target === 'dist') {
      return grunt.task.run(['build', 'connect:dist:keepalive']);
    }

    grunt.task.run([
      'prep',
      'connect:livereload',
      'watch'
    ]);
  });

  grunt.registerTask('build', [
    'clean:dist',
    'prep',
    'useminPrepare',
    'ngtemplates',
    'concat',
    'ngmin',
    'copy:dist',
    'cssmin',
    'uglify',
    'filerev',
    'usemin'
  ]);

  grunt.registerTask("default", ["serve"]);
};
