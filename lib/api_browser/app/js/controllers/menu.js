app.controller('MenuCtrl', function($scope, $state, Documentation) {
  var parentLookup = {};
  $scope.versions = [];
  $scope.resources = {};
  $scope.schemas = {};
  $scope.traits = {};
  $scope.selectedVersion = '';
  $scope.currentType = '';
  $scope.active = {};

  Documentation.versions().then(function(versions) {
    $scope.versions = versions;
    _.each(versions, function(version) {
      Documentation.items(version).then(function(items) {
        var resources = $scope.resources[version] = [];
        var schemas = $scope.schemas[version] = [];
        var traits = $scope.traits[version] = [];
        var children = [];
        _.each(items.resources, function(item, name) {
          var link = { name: item.display_name, stateRef: '' };

          parentLookup[name] = link;
          link.stateRef = $state.href('root.controller', { version: version, controller: name });
          link.id = name;

          link.actions = _.map(item.actions, function(action) {
            var actionLink = { name: action.name, stateRef: '' };
            parentLookup[name + '_action_' + action.name] = actionLink;
            actionLink.parent = name;
            actionLink.stateRef = $state.href('root.action', { version: version, controller: name, action: action.name });
            actionLink.id = name + '_action_' + action.name;
            actionLink.isAction = true;
            actionLink.parentRef = link;
            return actionLink;
          });
          link.childResources = [];
          if (item.parent) {
            link.parent = item.parent;
            children.push(link);
          } else {
            resources.push(link);
          }
        });
        _.each(items.schemas, function(item, name) {
          var link = { name: item.display_name, stateRef: '' };
          link.stateRef = $state.href('root.type', { version: version, type: item.id });
          link.id = name;
          schemas.push(link);
        });
        _.each(items.traits, function(item, name) {
          var link = { name: name, stateRef: '' };
          link.stateRef = $state.href('root.trait', { version: version, trait: name });
          link.id = name;
          traits.push(link);
        });
        _.each(children, function(link) {
          if (parentLookup[link.parent]) {
            link.parentRef = parentLookup[link.parent];
            parentLookup[link.parent].childResources.push(link);
          } else {
            throw 'No parent resource found';
          }
        });
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

  $scope.availableSchemas = function() {
    return $scope.schemas[$scope.selectedVersion];
  };

  $scope.availableTraits = function() {
    return $scope.traits[$scope.selectedVersion];
  };

  $scope.$on('$stateChangeSuccess', function(e, state, params) {
    if (params.version) $scope.selectedVersion = params.version;
    $scope.active.resources = state.name !== 'root.type' && state.name !== 'root.trait';
    $scope.active.schemas = state.name === 'root.type';
    $scope.active.traits = state.name === 'root.trait';
  });
});
