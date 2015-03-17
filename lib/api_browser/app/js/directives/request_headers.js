app.directive('rsRequestHeaders', function($compile, PayloadTemplates) {
  return {
    restrict: 'E',
    scope: {
      headers: '='
    },
    link: function(scope, element) {
      if(scope.headers.type) {
        scope.attributes = scope.headers.type.attributes;
      }

      PayloadTemplates.resolve('PraxisHeaders', 'Struct').then(function(template) {
        element.replaceWith($compile(template)(scope));
      });
    }
  };
});
