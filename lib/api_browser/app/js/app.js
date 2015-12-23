var app = angular.module('PraxisDocBrowser', ['ui.router', 'ui.bootstrap', 'ngSanitize']);

app.config(function ($stateProvider, $urlRouterProvider, $uiViewScrollProvider) {

  $uiViewScrollProvider.useAnchorScroll();

  $urlRouterProvider
    .otherwise('/');

  $stateProvider
    .state('root', {
      abstract: true,
      templateUrl: 'views/layout.html'
    })
    .state('root.home', {
      url: '/',
      templateUrl: 'views/home.html'
    })
    .state('root.controller', {
      url: '/:version/controller/:controller',
      templateUrl: 'views/controller.html',
      controller: 'ControllerCtrl'
    })
    .state('root.type', {
      url: '/:version/type/:type',
      templateUrl: 'views/type.html',
      controller: 'TypeCtrl'
    })
    .state('root.action', {
      url: '/:version/controller/:controller/:action',
      templateUrl: 'views/action.html',
      controller: 'ActionCtrl'
    })
    .state('root.trait', {
      url: '/:version/trait/:trait',
      templateUrl: 'views/trait.html',
      controller: 'TraitCtrl'
    })
    .state('root.builtin', {
      abstract: true,
      url: '/builtin',
      template: '<ui-view/>'
    })
    .state('root.builtin.field-selector', {
      url: '/field-selector',
      templateUrl: 'views/builtin/field-selector.html'
    });
});
