app.controller('TraitCtrl', function ($scope, $stateParams, Documentation) {
  $scope.traitName = $stateParams.trait;
  $scope.apiVersion = $stateParams.version;

  Documentation.trait($stateParams.version, $scope.traitName).then(function(data) {
    $scope.trait = data;
  }, function() {
    $scope.error = true;
  });
});
