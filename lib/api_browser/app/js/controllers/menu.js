app.controller('MenuCtrl', function($scope, $state, Documentation) {
  var parentLookup = {};
  $scope.versions = [];
  $scope.resources = {};
  $scope.others = {};
  $scope.selectedVersion = '';
  $scope.currentType = '';
  $scope.active = {};

  var menuPromise = Documentation.getIndex().success(function(index) {
    _.forEach(index, function(items, version) {
      $scope.versions.push(version);
      var resources = $scope.resources[version] = [];
      var others = $scope.others[version] = [];

      _.forEach(items, function(item, name) {
        var link = { name: name, stateRef: '' };
        if (item.parent) {
          link.parent = item.parent;
        }
        if (item.controller) {
          parentLookup[item.controller] = link;
          link.stateRef = $state.href('root.controller', { version: version, controller: item.controller });
          link.typeName = item.controller;
          resources.push(link);
        } else if (item.media_type) {
          link.stateRef = $state.href('root.type', { version: version, type: item.media_type });
          link.typeName = item.media_type;
          others.push(link);
        } else if (item.kind) {
          link.stateRef = $state.href('root.type', { version: version, type: item.kind });
          link.typeName = item.kind;
          others.push(link);
        }
      });
      function getPath(r) {
        if (r.parent) {
          var path = getPath(parentLookup[r.parent]) + ':' + _.last(r.typeName.split('-'));
          return path;
        }
        return _.last(r.typeName.split('-'));
      }
      $scope.resources[version] = _.map(_.sortBy(resources, getPath), function(r) {
        r.grandfather = grandfatherType(r.typeName);
        return r;
      });
    });
    var numeralVersions = _.filter($scope.versions, function(n) { return !isNaN(parseFloat(n)); })
                           .sort(function(a,b) { return parseFloat(b) - parseFloat(a); });
    $scope.selectedVersion = $state.params.version || numeralVersions[0] || $scope.versions[0];

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
