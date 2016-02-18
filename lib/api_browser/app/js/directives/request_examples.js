app.directive('requestExamples', function(Examples, $timeout) {
  return {
    restrict: 'E',
    scope: {
      action: '=',
      resource: '=',
      version: '='
    },
    template: '<tabset><tab ng-repeat="example in examples" heading="{{example.displayName}}" select="select(example.template)"></tab></tabset>',
    link: function(scope, element) {
      scope.examples = Examples.forContext(scope.action, scope.version, scope.resource);
      var keys = _.keys(scope.examples);
      if (keys.length === 1) {
        scope.examples[keys[0]].template.then(function(templateFn) {
          element.empty().append(templateFn(scope));
        });
      } else {
        scope.select = function(template) {
          template.then(function(templateFn) {
            $timeout(function() {
              element.find('.tab-content:eq(0)>.tab-pane.active:not(.initialized)').append(templateFn(scope)).addClass('initialized');
              template.then = _.noop;
            }, 100);
          });
        };
      }
    }
  };
});
