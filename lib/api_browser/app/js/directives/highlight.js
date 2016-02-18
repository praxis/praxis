app.directive('highlight', function() {
  return {
    restrict: 'EA',
    link: function ($scope, element, attrs) {
      var prism = window.Prism;
      prism.plugins.autoloader.languages_path = 'https://cdn.jsdelivr.net/prism/1.3.0/components/';
      element.ready(function() {
        element.html('<code>' + element.text() + '</code>');
        element.addClass('language-' + attrs.highlight);
        prism.highlightElement(element.find('code')[0]);
      });
    }
  };
});
