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
      name: '=?'
    },
    link: function(scope, element) {
      scope.apiVersion = $stateParams.version;
      templateFor(scope.type, scope.template).then(function(templateFn) {
        element.replaceWith(templateFn(scope));
      });
    }
  };
});
