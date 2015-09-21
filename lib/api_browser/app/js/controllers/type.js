app.controller('TypeCtrl', function ($scope, $stateParams, Documentation, normalizeAttributes) {
  $scope.typeId = $stateParams.type || $scope.controller.media_type.id;
  $scope.apiVersion = $stateParams.version;
  $scope.controllers = [];
  $scope.views = [];

  Documentation.getType($stateParams.version, $scope.typeId).then(function(response) {
    $scope.type = response.data;
    $scope.views = _(response.data.views)
      .map(function(view, name) { return _.extend(view, { name: name }); })
      .select(function(view) { return view.name !== 'master'; })
      .value();
    normalizeAttributes($scope.type, $scope.type.attributes);

    Documentation.getIndex().success(function(response) {
      $scope.controllers = _.select(response[$scope.apiVersion], function(item) { return item.controller && item.media_type == $scope.type.name; });
    });
  }, function() {
    $scope.error = true;
  });
});
