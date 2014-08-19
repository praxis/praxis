app.directive('rsAttributeTable', function() {
  return {
    restrict: 'E',
    templateUrl: 'views/directives/attribute_table.html',
    controller: function(){},
    scope: {
      attributes: '=',
      showGroups: '='
    },
    link: function(scope, element) {
      // create attribute groups
      scope.groups = [{attributes: []}];

      // handle required, optional
      if(scope.showGroups) {
        scope.groups[0].name = 'Required';
        scope.groups.push({name: 'Optional', attributes: []});
      }

      // map hash to array
      _(scope.attributes).forEach(function(attr, key) {
        attr.name = attr.name || key;
        scope.groups[(scope.showGroups && !attr.required ? 1 : 0)].attributes.push(attr);
      });
    }
  };
});
