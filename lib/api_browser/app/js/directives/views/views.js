app.directive("views", function() {

  return {
    restrict : "E",
    templateUrl : "js/directives/views/views.html",
    scope : {
      "collection" : "=",
    },
    link : function($scope) {
    }
  }

});