app.controller("ControllerCtrl", function($scope, $stateParams, Documentation) {
  $scope.controllerName = $stateParams.controller;
  $scope.apiVersion = $stateParams.version;

  Documentation.controller($stateParams.version, $stateParams.controller).then(function(response) {
    $scope.controller = response;
  }, function() {
    $scope.error = true;
  });
});
