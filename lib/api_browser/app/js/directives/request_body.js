app.directive('rsRequestBody', function($compile, PayloadTemplates) {
  return {
    restrict: 'E',
    scope: {
      payload: '='
    },
    link: function(scope, element, attrs) {
      // use the attribute type name to find the template
      var alt, name = (scope.payload.type ? scope.payload.type.name : null) || 'default';

      if(scope.payload.type) {
        scope.attributes = scope.payload.type.attributes;
      }

      if(name === 'Struct') {
        name = 'PraxisBody',
        alt = 'Struct'
      }

      PayloadTemplates.resolve(name, alt).then(function(template) {
        element.replaceWith($compile(template)(scope));
      });
    }
  }
});