app.filter('tagRequirement', function() {
  return function(groups) {
    if ( typeof groups === 'undefined' || groups.length == 0 ) {
      return "";
    }else if (groups.includes('all') ) {
      var title = "required attribute";
      return "<span class='required-attribute-mark' title=\""+title+"\" >*</span>"
    } else {
      var title = "conditionally required";
      return"<span class='conditional-attribute-mark' title=\""+title+"\" >*</span>"
    }
  };
});