app.directive('highlight', function() {
  return {
    restrict: 'EA',
    link: function ($scope, element, attrs) {
      element.ready(function() {
        var prism = window.Prism;
        element.html('<code>' + prism.highlight(element.text(), prism.languages[attrs.highlight], attrs.highlight) + '</code>');
      });
    }
  };
});
