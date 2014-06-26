app.controller("TypeCtrl", function ($scope, $stateParams, Documentation) {
  $scope.typeName = $stateParams.type || $scope.controller.media_type;
  $scope.apiVersion = $stateParams.version;
  $scope.controllers = [];
  $scope.views = [];

  Documentation.getType($stateParams.version, $scope.typeName).then(function(response) {
    $scope.type = response.data;
    $scope.views = _(response.data.views)
      .map(function(view, name) { return _.extend(view, { name: name }); })
      .select(function(view) { return view.name != 'master'; })
      .value();

    _.forEach($scope.type.attributes, function(attribute, name) {
      var example = JSON.stringify($scope.type.example[name], null, 2);
      if (!attribute.options) attribute.options = {};
      if (example) attribute.options.example = example;
      if (attribute.values) attribute.options.values = attribute.values;
      if (attribute.default) attribute.options.default = attribute.default;
    });

    Documentation.getIndex().success(function(response) {
      $scope.controllers = _.select(response[$scope.apiVersion], function(item) { return item.controller && item.media_type == $scope.typeName; });
    });
  }, function() {
    $scope.error = true;
  });
});
