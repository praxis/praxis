app.factory('normalizeAttributes', function() {
  function normalize(type, attributes, parent) {
    _.forEach(attributes, function(attribute, name) {
      var path = parent.concat([name]);
      if (!attribute.options) attribute.options = {};
      if (attribute.values != null) attribute.options.values = attribute.values;
      if (attribute.default != null) attribute.options.default = attribute.default;
      if (attribute.example != null) attribute.options.example = attribute.example;
      if (attribute.type && attribute.type.attributes) {
        normalize(type, attribute.type.attributes, path);
      }
    });
  }

  return function(type, attributes) {
    normalize(type, attributes, []);
  };
});
