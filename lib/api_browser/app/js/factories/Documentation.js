/**
 * This service gives access to the documentation metadata
 */
app.factory('Documentation', function($http, $q) {
  var versions = $q.when(/*REPLACE-WITH-JSON*/$http.get('api/index-new.json', { cache: true }).then(function(data) {
    return $q.all(_.map(data.data.versions, function(version) {
      return $http.get('api/' + version + '.json', {cache: true}).then(function(versionData) {
        return [version, versionData.data];
      });
    })).then(_.zipObject);
  })/*END-REPLACE*/);

  return {
    /**
     * Returns an array of version strings
     */
    versions: function() {
      return versions.then(_.keys);
    },
    /**
     * Returns a list of controllers and types, useful for generating navigation
     */
    items: function(version) {
      return versions.then(function(v) { return v[version]; });
    },
    /**
     * Returns description of a controller
     */
    controller: function(version, name) {
      return this.items(version).then(function(v) {
        return v.resources[name];
      });
    },

    /**
     * Returns a description of a type
     */
    type: function(version, name) {
      return versions.then(function(v) {
        return v[version].schemas[name];
      });
    }
  };
});
