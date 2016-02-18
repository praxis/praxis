app.factory('prepareTemplate', function($q, $http, $templateCache, $compile) {
  return function(result) {
    return $q.when(result).then(function(template) {
      if (_.isFunction(template)) {
        return template;
      } else if (_.isString(template)) {
        return $http.get(template, {cache: $templateCache}).then(function(response) {
          return $compile(response.data);
        });
      } else {
        throw 'Resolver returned an unknown type';
      }
    });
  };
});
