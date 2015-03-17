app.controller("ControllerCtrl", function($scope, $stateParams, Documentation) {
  $scope.controllerName = $stateParams.controller;
  $scope.apiVersion = $stateParams.version;

  Documentation.getController($stateParams.version, $stateParams.controller).then(function(response) {
    $scope.controller = response.data;
  }, function() {
    $scope.error = true;
  });
});
