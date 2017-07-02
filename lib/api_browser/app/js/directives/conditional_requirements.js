app.directive('conditionalRequirements', function() {
  return {
    restrict: 'E',
    scope: {
      requirements: '=',
    },
    templateUrl: 'views/types/embedded/requirements.html',
    link: function(scope, element, attrs) {
      // Reject requirements of type "all"
      scope.cond_requirements = _.reject(scope.requirements, function(req){
                             if( req.type == 'all')
                               return true;
                           });
    }
  };
});
