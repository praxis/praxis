/**
 * This directive adds the css position fixed if the tabs fit on screen
 */

app.directive('fixedIfFits', function($timeout) {
  return {
    restrict: 'C',
    link: function(scope, element) {
      $timeout(function() {
        var height = _(element.find('.tab-content .tab-pane').get()).map(function(el) {
          return angular.element(el).height();
        }).max() + element.offset().top;
        if (height < $(window).height()) {
          element[0].style.width = element.width() + 'px';
          element[0].style.position = 'fixed';
        }
      }, 100);
    }
  };
});
