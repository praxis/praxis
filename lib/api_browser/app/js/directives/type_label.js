app.directive('rsTypeLabel', function($compile, $templateCache, $http) {

  var primitives = [
    'Boolean',
    'CSV',
    'DateTime',
    'Float',
    'Hash',
    'Ids',
    'Integer',
    'Object',
    'String',
    'Struct'
  ];

  var templates = {
    primitive: '<span>{{type.name}}</span>',
    type: '<a ui-sref="root.type({version: apiVersion, type: type.name})">{{type.name | resourceName}}</a>',
    primitiveCollection: '<span>Collection&nbsp;[&nbsp;{{type.member_attribute.type.name}}&nbsp;]</a>',
    typeCollection: '<span>Collection&nbsp;[&nbsp;<a ui-sref="root.type({version: apiVersion, type: type.member_attribute.type.name})">{{type.member_attribute.type.name | resourceName}}</a>&nbsp;]</span>',
    link: '<span>Link&nbsp;[&nbsp;<a ui-sref="root.type({version: apiVersion, type: type.link_to})">{{type.link_to | resourceName}}</a>&nbsp;]</span>'
  };

  return {
    restrict: 'E',
    scope: {
      type: '='
    },
    link: function(scope, element) {

      var template = templates.type;
      if (_.contains(primitives, scope.type.name)) {
        template = templates.primitive;
      }
      else if ( scope.type.member_attribute !== undefined ) { 
        if ( _.contains(primitives, scope.type.member_attribute.type.name)){
          template = templates.primitiveCollection;
        }else{
          template = templates.typeCollection;
				}
      }
      else if (scope.type.link_to) {
        template = templates.link;
      }

      element.html(template);
      $compile(element.contents())(scope);
    },
    controller: function($scope, $stateParams) {
      $scope.apiVersion = $stateParams.version;
    }
  };
});
