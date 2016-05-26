app.filter('attributeName', function($sce) {
  return function(input) {
    var parts = input.split('.');
    if (parts.length > 1) {
      var prefix = _.take(parts, parts.length-1).join('.');
      return $sce.trustAsHtml('<span class="attribute-prefix">' + prefix + '.</span>' + _.last(parts));
    }
    return $sce.trustAsHtml(input);
  };
});
