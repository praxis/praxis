app.provider('Examples', function() {
  var registry = {};

  this.register = function(key, displayName, handler) {
    registry[key] = registry[key] || [];
    registry[key].unshift({
      key: key,
      displayName: displayName,
      handler: handler
    });
  };

  this.register('general', 'General', function() {
    return 'views/examples/general.html';
  });

  this.$get = function(prepareTemplate, $injector) {
    return {
      forContext: function(action, version) {
        var results = {};
        for (var key in registry) {
          for (var i = 0; i < registry[key].length; i++) {
            var result = $injector.invoke(registry[key][i].handler, this, {
              $action: action,
              $version: version
            });
            if (result) {
              results[key] = {
                key: key,
                displayName: registry[key][i].displayName,
                template: prepareTemplate(result)
              };
              break;
            }
          }
        }
        return results;
      }
    };
  };

});
