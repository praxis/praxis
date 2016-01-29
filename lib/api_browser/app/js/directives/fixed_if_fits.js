/**
 * This directive adds the css position fixed if the tabs fit on screen
 */

app.directive('fixedIfFits', function($timeout, $rootScope) {
  return {
    restrict: 'C',
    link: function(scope, element) {
      function recalculateLayout() {
        $timeout(function() {
          var height = _(element.find('.tab-content .tab-pane').get()).map(function(el) {
            return angular.element(el).height();
          }).concat([element[0].scrollHeight]).max() + element.offset().top + element.find('.row:first-of-type').height();
          var mq = window.matchMedia('(min-width: 768px)');
          if (height < $(window).height() && mq.matches) {
            var padding = 20;
            element[0].style.width = (element.width() + padding) + 'px';
            element[0].style.paddingRight = padding + 'px';
            var navbarHeight = '' + ($('.navbar').height() || 60) + 'px';
            element[0].style.height = 'calc(100vh - ' + navbarHeight + ')';
            element[0].style.paddingBottom = '30px';
            element[0].style['overflow-y'] = 'auto';
            element[0].style.position = 'fixed';
          } else {
            element[0].style.width = null;
            element[0].style.paddingRight = null;
            element[0].style.height = null;
            element[0].style.paddingBottom = null;
            element[0].style['overflow-y'] = null;
            element[0].style.position = 'static';
          }
        }, 100);
      }
      recalculateLayout();
      $rootScope.$on('$stateChangeSuccess', recalculateLayout);
    }
  };
});
