app.filter('headerInfo', function() {
  return function(info) {
    if (info.value !== true) {
      return info.value + ' (' + info.type + ')';
    } else {
      return '(any value)';
    }
  };
});