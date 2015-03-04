app.factory('Documentation', function($http) {
  return {
    getIndex: function() {
      return $http.get('api/index.json', { cache: true });
    },
    getController: function(version, name) {
      return $http.get('api/' + version + '/resources/' + name + '.json', { cache: true });
    },
    getType: function(version, name) {
      return $http.get('api/' + version + '/types/' + name + '.json', { cache: true });
    },
    getTemplates: function(version) {
      return $http.get('api/' + version + '/templates.json', { cache: true });
    }
  };
});
