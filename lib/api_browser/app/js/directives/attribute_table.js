/**
 * This directive is responsible for showing attributes in a table structure.
 */

app.directive('attributeTable', function() {
  return {
    restrict: 'E',
    templateUrl: 'views/directives/attribute_table.html',
    scope: {
      attributes: '=',
      showGroups: '='
    },
    link: function(scope) {
      scope.groups = [{attributes: []}];

      if(scope.showGroups) {
        scope.groups[0].name = 'Required';
        scope.groups.push({name: 'Optional', attributes: []});
      }

      _.forEach(scope.attributes, function(attr, key) {
        attr.name = attr.name || key;
        scope.groups[(scope.showGroups && !attr.required ? 1 : 0)].attributes.push(attr);
      });
    }
  };
});
