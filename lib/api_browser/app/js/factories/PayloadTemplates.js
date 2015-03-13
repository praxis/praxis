app.factory('PayloadTemplates', function($http, $templateCache, TemplateProvider) {

  var defaultTemplate = $http.get('views/directives/request_body/_default.html', { cache: $templateCache });

  var localTemplates = {
    'Struct': $http.get('views/directives/request_body/_struct.html', { cache: $templateCache })
  };

  return TemplateProvider(defaultTemplate, localTemplates, 'standalone');
});
