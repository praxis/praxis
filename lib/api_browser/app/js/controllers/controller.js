app.controller('ControllerCtrl', function($scope, $stateParams, Documentation, $anchorScroll, $timeout) {
  $scope.controllerName = $stateParams.controller;
  $scope.apiVersion = $stateParams.version;

  function scrollTo(id, time) {
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
  }

  Documentation.getController($stateParams.version, $stateParams.controller).then(function(response) {
    $scope.controller = response.data;
  }, function() {
    $scope.error = true;
  });

  $scope.$on('$stateChangeSuccess', function(e, state, params) {
    switch (state.name) {
    case 'root.controller.action':
      scrollTo('action-' + params.action, 10);
      break;
    case 'root.controller.action.response':
      scrollTo('action-' + params.action + '-' + params.response);
      break;
    }
  });
});
