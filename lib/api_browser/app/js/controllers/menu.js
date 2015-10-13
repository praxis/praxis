app.controller('MenuCtrl', function($scope, $state, Documentation) {
  var parentLookup = {};
  $scope.versions = [];
  $scope.resources = {};
  $scope.others = {};
  $scope.selectedVersion = '';
  $scope.currentType = '';
  $scope.active = {};

  Documentation.versions().then(function(versions) {
    $scope.versions = versions;
    var numeralVersions = _.filter(versions, function(n) { return !isNaN(parseFloat(n)); })
                           .sort(function(a,b) { return parseFloat(b) - parseFloat(a); });
    $scope.selectedVersion = $state.params.version || numeralVersions[0] || $scope.versions[0];

    _.each(versions, function(version) {
      Documentation.items(version).then(function(items) {
        $scope.links[version] = [];
        _.each(items.resources, function(item, id) {
          var link = { name: item.display_name, stateRef: '' };
          link.stateRef = $state.href('root.controller', { version: version, controller: id });
          link.typeId = id;
          $scope.links[version].push(link);
        });
        _.each(items.schemas, function(item, id) {
          var link = { name: item.display_name, stateRef: '' };
          link.stateRef = $state.href('root.type', { version: version, type: id });
          link.typeId = id;
          $scope.links[version].push(link);
        });
      });
    });
  });

  $scope.select = function(version) {
    $scope.selectedVersion = version;
  };

  $scope.availableResources = function() {
    return $scope.resources[$scope.selectedVersion];
  };

  $scope.availableOthers = function() {
    return $scope.others[$scope.selectedVersion];
  };

  function grandfatherType(id) {
    var self = parentLookup[id];
    if (self.parent) {
      return grandfatherType(self.parent);
    }
    return id;
  }

  $scope.$on('$stateChangeSuccess', function(e, state, params) {
    if (params.version) $scope.selectedVersion = params.version;
    $scope.currentType = params.controller || params.type;
    menuPromise.then(function() {
      $scope.selectedGrandfatherType = params.controller && grandfatherType(params.controller);
    });
    $scope.active.resources = state.name !== 'root.type';
    $scope.active.schemas = state.name === 'root.type';
  });
});
