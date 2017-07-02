app.filter('tagRequirement', function() {
  return function(groups) {
    if ( typeof groups === 'undefined' || groups.length == 0 ) {
      return "";
    }else if (groups.includes('all') ) {
      var title = "required attribute";
      return "<span title=\""+title+"\" style='font-weight:bold'><font color='red'>*</font></span>"
    } else {
      var title = "conditionally required";
      return"<span title=\""+title+"\"  style='font-weight:bold'><font color='orange'>*</font></span>"
    }
  };
});