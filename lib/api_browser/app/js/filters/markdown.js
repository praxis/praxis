app.filter('markdown', function() {
  var converter = new Showdown.converter();
  return _.memoize(function(input) {
    return input ? converter.makeHtml(input) : '';
  });
});
