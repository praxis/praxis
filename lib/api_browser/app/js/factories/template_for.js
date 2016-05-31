/**
 * Allows dynamic UI based on resolvers. You can customise the way templates
 * work in the doc browser by registering your own template resolver.
 *
 * A template resolver is dependency injected function that has several special
 * arguments that can be injected. These are:
 *
 * Name                | Type    | Description
 * --------------------|---------|----------------------------------------------
 * $type               | String  | The name of a type.
 * $family             | String  | The family or group of types this type belongs to.
 * $typeDefinition     | Object  | The full definition of the type as available.
 * $requestedTemplate  | String  | This is the kind of template that we want. Possible values are: standalone, embedded and label. Embedded templates represent types that are attributes of another type. The template thus should assume that it is being rendered in a table row. Label templates display a human readable name of a type. Standalone templates are used when a type is displayed by itself (i.e. a request payload).
 *
 * The type resolver should return either a $compiled template, or a url of a
 * template or a promise for one of those. In that case the template resolution
 * procedure will halt and the returned template will be displayed. If `undefined`
 * is passed, the next resolver will be invoked. A promise for undefined is currently
 * not supported.
 */
app.provider('templateFor', function() {

  var resolvers = [];
  /**
   * Register a custom template resolver.
   * @param {function} resolver
   *    A function that returns undefined or a promise for a compiled template or a template url.
   */
  this.register = function(resolver) {
    resolvers.unshift(resolver);
  };

  this.register(function payloadResolver($family, $requestedTemplate) {
    'ngInject';
    if ($requestedTemplate === 'standalone') {
      switch ($family) {
        case 'hash':
          return 'views/types/standalone/struct.html';
        case 'array':
          return 'views/types/standalone/array.html';
        default:
          return 'views/types/standalone/default.html';
      }
    }
  });

  this.register(function typeResolver($family, $type, $requestedTemplate) {
    'ngInject';
    if ($requestedTemplate === 'embedded') {
      if ($type === 'Links') {
        return 'views/types/embedded/links.html';
      }
      if ($type === 'Praxis::Extensions::FieldSelection::FieldSelector') {
        return 'views/types/embedded/field-selector.html';
      }
      switch ($family) {
        case 'hash':
          return 'views/types/embedded/struct.html';
        default:
          return 'views/types/embedded/default.html';
      }
    }
  });

  this.register(function labelResolver($typeDefinition, $requestedTemplate, primitives) {
    'ngInject';
    if ($requestedTemplate === 'label') {
      if ( $typeDefinition.member_attribute !== undefined) {
        if ($typeDefinition.member_attribute.anonymous || _.contains(primitives, $typeDefinition.name)) {
          return 'views/types/label/primitive_collection.html';
        } else{
          return 'views/types/label/type_collection.html';
        }
      } else if ($typeDefinition.anonymous || _.contains(primitives, $typeDefinition.name)) {
        return 'views/types/label/primitive.html';
      } else if ($typeDefinition.link_to) {
        return 'views/types/label/link.html';
      }
      return 'views/types/label/type.html';
    }
  });

  this.register(function homePageResolver($family, $requestedTemplate) {
    'ngInject';
    if ($requestedTemplate === 'home') {
      switch ($family) {
        case 'hash':
          return 'views/types/home/struct.html';
        case 'array':
          return 'views/types/home/array.html';
        default:
          return 'views/types/home/default.html';
      }
    }
  });

  this.$get = function($injector, prepareTemplate) {
    return function(type, templateType) {
      for (var i = 0; i < resolvers.length; i++) {
        var result = $injector.invoke(resolvers[i], this, {
          $type: type.name,
          $typeDefinition: type,
          $family: type.family || type.name,
          $requestedTemplate: templateType
        });
        if (result) {
          return prepareTemplate(result);
        }
      }
      throw 'Template did not match any resolver.';
    };
  };
})
.constant('primitives', [
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
]);
