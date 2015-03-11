app.filter('markdown', function() {
  var converter = new Showdown.converter();
  return function(input) {
    return input? converter.makeHtml(input) : '';
  };
});