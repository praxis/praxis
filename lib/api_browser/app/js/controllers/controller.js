app.controller('ControllerCtrl', function($scope, $stateParams, Documentation, $anchorScroll, $timeout) {
  $scope.controllerName = $stateParams.controller;
  $scope.apiVersion = $stateParams.version;

  Documentation.getController($stateParams.version, $stateParams.controller).then(function(response) {
    $scope.controller = response.data;
  }, function() {
    $scope.error = true;
  });

  $scope.$on('$stateChangeSuccess', function(e, state, params) {
    if (state.name == 'root.controller.action') {
      (function scrollTo(id, time) {
        if (angular.element('#' + id).length > 0) {
          if (time > 20) {
            $timeout(function() {
              $anchorScroll.yOffset = angular.element('.header .navbar');
              $anchorScroll(id);
            }, 400);
          } else {
            $anchorScroll.yOffset = angular.element('.header .navbar');
            $anchorScroll(id);
          }
        } else {
          $timeout(function() {
            scrollTo(id, 2 * time);
          }, time);
        }
      })('action-' + params.action, 10);
    }
  });
});
