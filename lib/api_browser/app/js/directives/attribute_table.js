app.directive('rsAttributeTable', function($compile, $templateCache, $http) {
  return {
    restrict: 'E',
    templateUrl: 'views/directives/attribute_table.html',
    scope: {
      attributes: '=',
      showGroups: '='
    },
    link: function(scope, element) {

      var tbody = element.find('tbody');
      var index = 0;
      var attributes = [];
      var p = 0;

      // expand sub attributes
      _(scope.attributes)
        .map(function(attribute, name) {
          return {
            name: name,
            details: attribute,
            required: attribute.required ? 1 : 2
          };
        })
        .sortBy('required')
        .forEach(function(attribute) {

          if (scope.showGroups && p < attribute.required) {
            attributes.push({
              name: attribute.details.required ? 'Required' : 'Optional',
              details: {
                type: {
                  name: 'Group'
                }
              }
            });
            p = attribute.required;
          }

          attributes.push(attribute);

          if (attribute.details.type.name === 'Struct' || attribute.details.type.links_struct) {
            _.forEach(attribute.details.type.attributes, function(subAttribute, subName) {
              attributes.push({
                name: attribute.name + '.' + subName,
                details: subAttribute
              });
            });
          }
        });

      _.forEach(attributes, function(attribute, index) {
        // custom templates can be specified here
        var templatePath = 'views/directives/attribute_table/_default.html';
        if (attribute.details.type.name === "Group") {
          templatePath = 'views/directives/attribute_table/_group.html';
        }

        $http.get(templatePath, { cache: $templateCache }).success(function(template) {
          var row = $(template);
          var rowScope = scope.$new(true);
          rowScope.attribute = attribute;
          $compile(row)(rowScope);

          // Since this is a promise callback, we need to ensure the row is inserted in order
          var length = tbody.children().length;
          if (!length) {
            tbody.append(row);
          }
          else {
            var position = Math.min(index, length) - 1;
            if (position < 0)
              tbody.children().first().before(row);
            else
              tbody.children().eq(position).after(row);
          }
        });

      });
    }
  };
});
