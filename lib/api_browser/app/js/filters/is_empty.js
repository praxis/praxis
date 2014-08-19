app.filter('isEmpty', function() {
  return function(input) {
    return (input === undefined) ||
        (input === null) ||
        jQuery.isEmptyObject(input) ||
        (input instanceof Array && !input.length);
  };
});
