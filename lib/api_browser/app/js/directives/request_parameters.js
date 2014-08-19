app.directive('rsRequestParameters', function($compile, PayloadTemplates) {
  return {
    restrict: 'E',
    scope: {
      parameters: '='
    },
    link: function(scope, element, attrs) {
      // use the attribute type name to find the template
      var name = (scope.parameters.type ? scope.parameters.type.name : null) || 'default';

      if(scope.parameters.type) {
        scope.attributes = scope.parameters.type.attributes;
      }

      PayloadTemplates.resolve('PraxisParameters', 'Struct').then(function(template) {
        element.replaceWith($compile(template)(scope));
      });
    }
  }
});