describe('Configuration', function() {
  var theConfigProvider, runFn;
  beforeEach(function() {
    angular.module('PraxisDocBrowser').config(function(ConfigurationProvider) {
      theConfigProvider = ConfigurationProvider;
    });
    runFn = angular.module('PraxisDocBrowser')._runBlocks[0];
  });

  beforeEach(angular.mock.module('PraxisDocBrowser'));

  beforeEach(inject(function(Configuration) {
    Configuration;
  }));

  it('sets sensible defaults', function() {
    expect(theConfigProvider).toEqual(jasmine.objectContaining({
      title: 'API Browser',
      versionLabel: 'API Version',
      expandChildren: true
    }));
  });

  it('assigns all things from the provider unto the root scope', inject(function($injector, $rootScope) {
    $injector.invoke(runFn);
    expect($rootScope).toEqual(jasmine.objectContaining({
      title: 'API Browser',
      versionLabel: 'API Version',
      expandChildren: true
    }));
  }));
});
