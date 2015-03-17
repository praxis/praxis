app.controller('MenuCtrl', function($scope, $state, Documentation) {

  $scope.versions = [];
  $scope.links = {};
  $scope.selectedVersion = '';
  $scope.currentType = '';

  Documentation.getIndex().success(function(index) {

    _.forEach(index, function(items, version) {
      $scope.versions.push(version);
      var links = $scope.links[version] = [];

      _.forEach(items, function(item, name) {
        var link = { name: name, stateRef: '' };

        if (item.controller) {
          link.stateRef = $state.href('root.controller', { version: version, controller: item.controller });
          link.typeName = item.controller;
        }
        else if (item.media_type) {
          link.stateRef = $state.href('root.type', { version: version, type: item.media_type });
          link.typeName = item.media_type;
        }
        else if (item.kind) {
          link.stateRef = $state.href('root.type', { version: version, type: item.kind });
          link.typeName = item.kind;
        }

        links.push(link);
      });
    });
    var numeralVersions = _.filter($scope.versions, function(n) { return !isNaN(parseFloat(n)); })
                           .sort(function(a,b) { return parseFloat(b) - parseFloat(a); });
    $scope.selectedVersion = $state.params.version || numeralVersions[0] || $scope.versions[0];

  });

  $scope.select = function(version) {
    $scope.selectedVersion = version;
  };

  $scope.availableLinks = function() {
    return $scope.links[$scope.selectedVersion];
  };

  $scope.$on('$stateChangeSuccess', function(e, state, params) {
    if (params.version) $scope.selectedVersion = params.version;
    $scope.currentType = params.controller || params.type;
  });
});
