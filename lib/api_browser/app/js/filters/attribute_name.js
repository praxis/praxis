app.filter('attributeName', function($sce) {
  return function(input) {
    var parts = input.split('.');
    if (parts.length > 1) {
      var prefix = parts.slice(0,parts.length-1).join('.')
      return $sce.trustAsHtml('<span class="attribute-prefix">' + prefix + '.</span>' + parts[parts.length-1]);
    }
    return $sce.trustAsHtml(input);
  };
});
