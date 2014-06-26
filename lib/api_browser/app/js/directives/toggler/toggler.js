app.directive("toggler", function() {
  return {
    restrict : "E",
    templateUrl : "js/directives/toggler/toggler.html",
    scope : {
      "change" : "="
    },
    link : function($scope) {
      // initially we display attributes
      $scope.mode = false;
    }
  }
});