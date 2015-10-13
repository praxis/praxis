app.controller('TypeCtrl', function ($scope, $stateParams, Documentation, normalizeAttributes) {
  $scope.typeId = $stateParams.type || $scope.controller.media_type.id;
  $scope.apiVersion = $stateParams.version;
  $scope.controllers = [];
  $scope.views = [];

  Documentation.type($stateParams.version, $scope.typeId).then(function(data) {
    $scope.type = data;
    $scope.views = _(data.views)
      .map(function(view, name) { return _.extend(view, { name: name }); })
      .select(function(view) { return view.name !== 'master'; })
      .value();
    normalizeAttributes($scope.type, $scope.type.attributes);

    Documentation.items($scope.apiVersion).then(function(response) {
      $scope.controllers = _.select(response.resources, function(item, id) {
        item.id = id;
        return item.media_type.id == $scope.type.id;
      });
    });
  }, function() {
    $scope.error = true;
  });
});
