﻿app.directive('rsAttributeDescription', function($compile, $templateCache, $http) {
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

        switch (name) {
          case 'example':
            templatePath = 'views/directives/attribute_description/_example.html';
        }

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

      })
    }
  };
});
