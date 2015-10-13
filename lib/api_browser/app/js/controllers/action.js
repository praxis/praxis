app.controller('ActionCtrl', function($scope, $stateParams, Documentation, normalizeAttributes) {
  $scope.controllerName = $stateParams.controller;
  $scope.actionName = $stateParams.action;
  $scope.apiVersion = $stateParams.version;

  Documentation.controller($stateParams.version, $stateParams.controller).then(function(data) {
    $scope.action = _.find(data.actions, function(action) { return action.name === $scope.actionName; });
    if (!$scope.action) {
      $scope.error = true;
      return;
    }
  });

  $scope.responses = [];
  _.forEach($scope.action.responses, function(response, name) {
    response.name = name;
    response.options = {
      headers: response.headers
    };

    response.jsonExample = _.get(response, 'payload.examples.json');

    $scope.responses.push(response);

    if(response.parts_like) {
      response.parts_like.isMultipart = true;
      response.parts_like.options = {
        headers: response.parts_like.headers
      };
      $scope.responses.push(response.parts_like);
    }
  });

  $scope.hasResponses = function() {
    return $scope.action ? _.any($scope.action.responses) : false;
  };

  $scope.hasResponseExample = function(response) {
    return response.jsonExample;
  };
});
