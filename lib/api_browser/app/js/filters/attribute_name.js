app.filter('attributeName', function($sce) {
  return function(input) {
    var parts = input.split('.');
    if (parts.length == 2) {
      return $sce.trustAsHtml('<span class="attribute-prefix">' + parts[0] + '.</span>' + parts[1]);
    }
    return $sce.trustAsHtml(input);
  };
});
