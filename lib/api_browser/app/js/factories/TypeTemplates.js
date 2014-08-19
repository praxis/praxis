app.factory('TypeTemplates', function($http, $templateCache, TemplateProvider) {

  var defaultTemplate = $http.get('views/directives/attribute_table_row/_default.html', { cache: $templateCache });

  var localTemplates = {
    "Struct": $http.get('views/directives/attribute_table_row/_struct.html', { cache: $templateCache }),
    "Links": $http.get('views/directives/attribute_table_row/_links.html', { cache: $templateCache })
  };

  return TemplateProvider(defaultTemplate, localTemplates, "embedded");
});
