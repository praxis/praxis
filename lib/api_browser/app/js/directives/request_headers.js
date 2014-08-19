app.directive('rsRequestHeaders', function($compile, PayloadTemplates) {
  return {
    restrict: 'E',
    scope: {
      headers: '='
    },
    link: function(scope, element, attrs) {
      // use the attribute type name to find the template
      var name = (scope.headers.type ? scope.headers.type.name : null) || 'default';

      if(scope.headers.type) {
        scope.attributes = scope.headers.type.attributes;
      }

      PayloadTemplates.resolve('PraxisHeaders', 'Struct').then(function(template) {
        element.replaceWith($compile(template)(scope));
      });
    }
  }
});