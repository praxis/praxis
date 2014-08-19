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
          var example = set.example ? JSON.stringify(set.example[name], null, 2) : '';
          if (!attribute.options) attribute.options = {};
          if (example) attribute.options.example = example;
          if (attribute.values) attribute.options.values = attribute.values;
          if (attribute.default) attribute.options.default = attribute.default;
        });
      }
    });

    $scope.responses = [];
    _.forEach($scope.action.responses, function(response, name) {
      response.name = name;
      response.options = {
        headers: response.headers
      }
      $scope.responses.push(response);

      if(response.parts_like) {
        response.parts_like.isMultipart = true;
        response.parts_like.options = {
          headers: response.parts_like.headers
        }
        $scope.responses.push(response.parts_like);
      }
    });

  }, function() {
    $scope.error = true;
  })

  $scope.hasResponses = function() {
    return $scope.action ? _.any($scope.action.responses) : false;
  };
});
