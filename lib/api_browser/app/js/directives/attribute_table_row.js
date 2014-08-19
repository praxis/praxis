app.directive('rsAttributeTableRow', function($compile, TypeTemplates) {
  return {
    restrict: 'E',
    scope: {
      name: '=',
      attribute: '='
    },
    link: function(scope, element, attrs) {
      // use the attribute type name to find the template
      var name = (scope.attribute.type ? scope.attribute.type.name : null) || 'default';
      
      TypeTemplates.resolve(name).then(function(template) {
        element.replaceWith($compile(template)(scope));
      });
    }
  }
});