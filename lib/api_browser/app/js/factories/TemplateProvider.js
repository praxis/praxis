app.factory('TemplateProvider', function($q, $http, $templateCache, $stateParams, Documentation) {
  // creates a template resolver
  return function(defaultTemplate, localTemplates, prefix){
    return {
      resolve: function(name, alt) {
        var deferred = $q.defer();
        var getTemplate = function(customTemplates) {
          var nsIdx;
          while(true) {
            if(customTemplates[prefix] && customTemplates[prefix][name]) {
              deferred.resolve(customTemplates[prefix][name]);
              break;
            } else if (localTemplates[name]) {
              localTemplates[name].then(function(response) {
                deferred.resolve(response.data);
              });
              break;
            } else {
              nsIdx = name.indexOf('::');
              if(nsIdx > 0) {
                name = name.substr(nsIdx + 2);
              } else if(alt) {
                name = alt;
                alt = null;
              } else {
                defaultTemplate.then(function(response) {
                  deferred.resolve(response.data);
                });
                break;
              }
            }
          }
        };

        Documentation.getTemplates($stateParams.version).then(function(response) {
          getTemplate(response.data);
        }, function() {
          getTemplate({});
        });

        return deferred.promise;
      }
    };
  };
});
