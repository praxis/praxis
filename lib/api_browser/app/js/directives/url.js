/**
 * This directive is responsible to render a URL for an action
 */
app.directive('url', function() {
  return {
    restrict: 'EA',
    scope: {
      action: '=',
      example: '@'
    },
    templateUrl: 'views/directives/url.html',
    link: function(scope, element, attrs) {
      scope.showExample = scope.example == 'example' || scope.example == 'true' || 'example' in attrs;
    }
  };
});
