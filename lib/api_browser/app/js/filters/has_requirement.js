app.filter('hasRequirement', function() {
  return function([parent_reqs, attr_name]) {
    var name = _.last(attr_name.split('.'));
    var groups=[]
    if( parent_reqs.length > 0 ){
      _.each(parent_reqs, function(reqdef) {
        if( reqdef.attributes.includes(name) ){
          groups.push(reqdef.type);
        }
      });
    }
    return groups;
  };
});
