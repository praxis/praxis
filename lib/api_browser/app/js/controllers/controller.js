app.controller("ControllerCtrl", function($scope, $stateParams, Documentation, $anchorScroll) {
  $scope.controllerName = $stateParams.controller;
  $scope.apiVersion = $stateParams.version;

  $scope.goToAction = function(name) {
    $anchorScroll.yOffset = angular.element('.header .navbar');
    $anchorScroll('action-' + name);
  }

  Documentation.getController($stateParams.version, $stateParams.controller).then(function(response) {
    $scope.controller = response.data;
  }, function() {
    $scope.error = true;
  });
});
