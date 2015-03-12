app.directive('rsRequestParameters', function($compile, PayloadTemplates) {
  return {
    restrict: 'E',
    scope: {
      parameters: '='
    },
    link: function(scope, element) {
      if(scope.parameters.type) {
        scope.attributes = scope.parameters.type.attributes;
      }

      PayloadTemplates.resolve('PraxisParameters', 'Struct').then(function(template) {
        element.replaceWith($compile(template)(scope));
      });
    }
  };
});
