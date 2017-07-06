app.directive('conditionalRequirements', function() {
  return {
    restrict: 'E',
    scope: {
      requirements: '=',
    },
    templateUrl: 'views/types/embedded/requirements.html',
    link: function(scope, element, attrs) {
      // Reject requirements of type "all"
      scope.condRequirements = _.reject(scope.requirements, {type: 'all'});
    }
  };
});
