app.filter('friendlyJson', function() {
  return function(input) {
    return JSON.stringify(input, null, 2);
  };
});