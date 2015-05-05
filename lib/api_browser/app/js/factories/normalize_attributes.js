app.factory('normalizeAttributes', function() {
  function normalize(type, attributes, parent) {
    _.forEach(attributes, function(attribute, name) {
      var path = parent.concat([name]);
      var example = JSON.stringify(_.get(type.example, path), null, 2);
      if (!attribute.options) attribute.options = {};
      if (example) attribute.options.example = example;
      if (attribute.values != null) attribute.options.values = attribute.values;
      if (attribute.default != null) attribute.options.default = attribute.default;
      if (attribute.type && attribute.type.attributes) {
        normalize(type, attribute.type.attributes, path);
      }
    });
  }

  return function(type, attributes) {
    normalize(type, attributes, []);
  };
});
