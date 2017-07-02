/**
 * This directive replaces itself with a specialised type template based on the
 * type it is displaying.
 */
app.directive('typePlaceholder', function(templateFor, $stateParams) {
  return {
    restrict: 'EA',
    scope: {
      type: '=',
      template: '@',
      details: '=?',
      name: '=?',
      parentrequirements: '=?',
    },
    link: function(scope, element) {

      scope.apiVersion = $stateParams.version;

      if( typeof scope.parentrequirements === 'undefined'){
        if( typeof scope.type.requirements !== 'undefined' && scope.type.requirements.length > 0){
          scope.parentrequirements = scope.type.requirements;
        }
      }

      templateFor(scope.type, scope.template).then(function(templateFn) {
        element.replaceWith(templateFn(scope));
      });
    }
  };
});
