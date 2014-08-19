app.filter('resourceName', function() {
  return function(input) {
    return _.last(input.split("::"));
  };
});