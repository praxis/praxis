app.factory('Repeater', function() {
  function Repeater(expression) {
    var match = expression.match(/^\s*([\s\S]+?)\s+in\s+([\s\S]+?)(?:\s+as\s+([\s\S]+?))?(?:\s+track\s+by\s+([\s\S]+?))?\s*$/);

    var lhs = match[1];
    this.rhs = match[2];
    this.aliasAs = match[3];
    this.trackByExp = match[4];

    match = lhs.match(/^(?:(\s*[\$\w]+)|\(\s*([\$\w]+)\s*,\s*([\$\w]+)\s*\))$/);

    this.valueIdentifier = match[3] || match[1];
    this.keyIdentifier = match[2];
  }

  Repeater.prototype.$watch = function(fn) {
    this.$scope.$watchCollection(this.rhs, fn);
  };

  Repeater.prototype.$transclude = function(length, value, key, index, fn) {
    var self = this;
    self._transclude(function(clone, scope) {
      scope[self.valueIdentifier] = value;
      if (self.keyIdentifier) scope[self.keyIdentifier] = key;
      scope.$index = index;
      scope.$first = (index === 0);
      scope.$last = (index === (length - 1));
      scope.$middle = !(scope.$first || scope.$last);
      // jshint bitwise: false
      scope.$odd = !(scope.$even = (index&1) === 0);
      // jshint bitwise: true
      fn(clone, scope);
    });
  };

  return {
    compile: function(repeatAttr, linkFn) {
      return function(element, attrs) {
        var expression = attrs[repeatAttr];
        var repeater = new Repeater(expression);
        return function($scope, $element, $attr, ctrl, $transclude) {
          repeater._transclude = $transclude;
          repeater.$scope = $scope;
          linkFn($scope, $element, $attr, ctrl, repeater);
        };
      };
    }
  };
});
app.directive('readableList', function(Repeater) {

  return {
    restrict: 'E',
    transclude: true,
    compile: Repeater.compile('repeat', function($scope, $element, $attr, ctrl, $repeat) {
      $repeat.$watch(function(inputList) {
        $element.empty();
        if (inputList.length == 1) {
          $repeat.$transclude(1, inputList[0], null, 0, function(clone) {
            $element.append(clone);
          });
        } else {
          var finalJoin = ' and ';

          var join = ', ',
              arr = inputList.slice(0),
              last = arr.pop(),
              beforeLast = arr.pop();

          _.each(arr, function(data, index) {
            $repeat.$transclude(inputList.length, data, null, index, function(clone) {
              $element.append(clone);
              $element.append(document.createTextNode(join));
            });
          });
          $repeat.$transclude(inputList.length, beforeLast, null, inputList.length - 2, function(clone) {
            $element.append(clone);
            $element.append(document.createTextNode(finalJoin));
          });
          $repeat.$transclude(inputList.length, last, null, inputList.length - 1, function(clone) {
            $element.append(clone);
          });
        }
      });
    })
  };
});
