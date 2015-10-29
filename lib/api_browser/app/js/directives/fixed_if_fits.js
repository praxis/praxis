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
        var mq = window.matchMedia('(min-width: 768px)');
        if (height < $(window).height() && mq.matches) {
          var padding = 20;
          element[0].style.width = (element.width() + padding) + 'px';
          element[0].style.paddingRight = padding + 'px';
          var navbarHeight = '' + ($('.navbar').height() || 60) + 'px';
          element[0].style.height = 'calc(100vh - ' + navbarHeight + ')';
          element[0].style.paddingBottom = '30px';
          element[0].style.overflow = 'auto';
          element[0].style.position = 'fixed';
        }
      }, 100);
    }
  };
});
