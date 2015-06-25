app.controller('ActionCtrl', function($scope, $stateParams, Documentation, normalizeAttributes) {
  $scope.controllerName = $stateParams.controller;
  $scope.actionName = $stateParams.action;
  $scope.apiVersion = $stateParams.version;


  // Extract the example and attach it to each attribute
  _.forEach(['headers', 'params', 'payload'], function(n) {
    var set = $scope.action[n];
    if (set) {
      normalizeAttributes(set, set.type.attributes);
    }
  });

  $scope.responses = [];
  _.forEach($scope.action.responses, function(response, name) {
    response.name = name;
    response.options = {
      headers: response.headers
    };
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
});
