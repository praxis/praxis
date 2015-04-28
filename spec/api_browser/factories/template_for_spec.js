describe('templateFor service', function() {
  var $scope, templateFor, $http, customResolver;

  beforeEach(angular.mock.module('PraxisDocBrowser'));

  beforeEach(function() {
    customResolver = function() {};
    angular.module('PraxisDocBrowser').config(function(templateForProvider) {
      templateForProvider.register(function($type, $family) {
        return customResolver($type, $family);
      });
    });
  });

  beforeEach(inject(function($rootScope, $injector) {
    $scope = $rootScope.$new();
    $http = $injector.get('$http');
    templateFor = $injector.get('templateFor');
  }));

  describe('default templates', function() {
    beforeEach(inject(function($templateCache) {
      $templateCache.put('views/types/standalone/struct.html', '<div>standalone -> Struct</div>');
      $templateCache.put('views/types/standalone/default.html', '<div>standalone -> Default</div>');
      $templateCache.put('views/types/embedded/links.html', '<div>embedded -> Links</div>');
      $templateCache.put('views/types/embedded/struct.html', '<div>embedded -> Struct</div>');
      $templateCache.put('views/types/embedded/default.html', '<div>embedded -> Default</div>');
    }));
    _.each(['standalone', 'embedded'], function(templateType) {
      _.each([
        {name: 'Struct', family: 'Struct'},
        {name: 'Links', family: 'Struct'},
        {name: 'Default', family: 'Numeric'}
      ], function(type) {
        it('resolve ' + templateType + ' ' + type.name, function() {
          var result;
          templateFor(type, templateType).then(function(template) {
            result = template($scope);
          });
          $scope.$apply();
          var name = templateType === 'standalone' && type.name === 'Links' ? type.family : type.name;
          expect(result.text().split(' -> ')).toEqual([templateType, name]);
        });
      });
    });
  });

  describe('custom templates', function() {
    var result;
    beforeEach(inject(function($templateCache) {
      $templateCache.put('views/mytype.html', '<div>custom</div>');
      customResolver = jasmine.createSpy().and.returnValue('views/mytype.html');
      templateFor({name: 'Custom', family: 'CustomFamily'}, true).then(function(template) {
        result = template($scope);
      });
      $scope.$apply();
    }));

    it('calls the custom resolver', function() {
      expect(customResolver).toHaveBeenCalledWith('Custom', 'CustomFamily');
    });

    it('returns the custom template', function() {
      expect(result.text()).toEqual('custom');
    });
  });
});
