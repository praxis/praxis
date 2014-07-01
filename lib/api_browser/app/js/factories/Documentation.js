app.factory('Documentation', function($http) {
  return {
    getIndex: function() {
      return $http.get('docs/index.json', { cache: true });
    },
    getController: function(version, name) {
      return $http.get('docs/' + version + '/resources/' + name + '.json', { cache: true });
    },
    getType: function(version, name) {
      return $http.get('docs/' + version + '/types/' + name + '.json', { cache: true });
    }
  };
});
