app.directive('rsAttributeDescription', function($compile, $templateCache, $http) {
  return {
    restrict: 'E',
    templateUrl: 'views/directives/attribute_description.html',
    scope: {
      attribute: '='
    },
    link: function(scope, element) {
      var list = element.find('dl');

      _.forEach(scope.attribute.options, function(option, name) {
        var templatePath = 'views/directives/attribute_description/_default.html';
        var skip_keys = ['reference','dsl_compiler','dsl_compiler_options'];
        
        switch (name) {
          case 'example':
            // expects string
            if(typeof option !== 'string') {
              option = JSON.stringify(option, null, 2);
            }
            templatePath = 'views/directives/attribute_description/_example.html';
            break;
          case 'headers':
            templatePath = 'views/directives/attribute_description/_headers.html';
            break;
        }

        if( ! _.contains( skip_keys, name ) ) {
          $http.get(templatePath, { cache: $templateCache }).success(function(template) {
            var row = $(template);
            var rowScope = scope.$new(true);
  
            rowScope.row = {
              name: name,
              value: option
            };
  
            $compile(row)(rowScope);
            list.append(row);
          });
        }
        
      })
    }
  };
});
