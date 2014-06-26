app.controller("ActionCtrl", function($scope, $stateParams, Documentation) {
  $scope.controllerName = $stateParams.controller;
  $scope.actionName = $stateParams.action;
  $scope.apiVersion = $stateParams.version;

  Documentation.getController($stateParams.version, $stateParams.controller).then(function(response) {
    $scope.action = _.find(response.data.actions, function(action) { return action.name === $scope.actionName; });
    if (!$scope.action) {
      $scope.error = true;
      return;
    }

    // Extract the example and attach it to each attribute
    _.forEach(['headers', 'params', 'payload'], function(n) {
      var set = $scope.action[n];
      if (set) {
        _.forEach(set.type.attributes, function(attribute, name) {
          var example = JSON.stringify(set.example[name], null, 2);
          if (!attribute.options) attribute.options = {};
          if (example) attribute.options.example = example;
          if (attribute.values) attribute.options.values = attribute.values;
          if (attribute.default) attribute.options.default = attribute.default;
        });
      }
    });

    _.forEach(action.responses, function(response) {
      response.options = {};
      _.forEach(['media_type', 'location', 'headers', 'multipart'], function(property) {
        if (response[property]) response.options[property] = response[property];
      })
    });

  }, function() {
    $scope.error = true;
  })

  $scope.hasResponses = function() {
    return $scope.action ? _.any($scope.action.responses) : false;
  };
});
