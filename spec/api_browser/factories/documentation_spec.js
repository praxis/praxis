describe('Documentation service', function() {
  var $scope, Documentation, $httpBackend;

  beforeEach(angular.mock.module('PraxisDocBrowser'));

  beforeEach(inject(function($rootScope, $injector) {
    $httpBackend = $injector.get('$httpBackend');
    $httpBackend.expectGET('api/index-new.json').respond({
      versions: ['1.0', '2.0']
    });
    $httpBackend.expectGET('api/1.0.json').respond({
      resources: {
        foo: {

        }
      },
      schemas: {
        bar: {

        }
      }
    });
    $httpBackend.expectGET('api/2.0.json').respond({
      resources: {
        test: 'TestCTRL'
      },
      schemas: {
        testType: 'TestType'
      }
    });
    $scope = $rootScope.$new();
    Documentation = $injector.get('Documentation');
    $httpBackend.flush();
  }));

  afterEach(function() {
    $httpBackend.verifyNoOutstandingExpectation();
    $httpBackend.verifyNoOutstandingRequest();
  });

  describe('#versions', function() {
    var versions;
    beforeEach(function() {
      Documentation.versions().then(function(v) {
        versions = v;
      });
      $scope.$apply();
    });
    it('returns both versions', function() {
      expect(versions).toEqual(['1.0', '2.0']);
    });
  });

  describe('#items', function() {
    var items;
    beforeEach(function() {
      Documentation.items('1.0').then(function(data) {
        items = data;
      });
      $scope.$apply();
    });

    it('returns all items for 1.0', function() {
      expect(items).toEqual({
        resources: {
          foo: { }
        },
        schemas: {
          bar: {}
        }
      });
    });
  });
  describe('#controller', function() {
    var item;
    beforeEach(function() {
      Documentation.controller('2.0', 'test').then(function(data) {
        item = data;
      });
      $scope.$apply();
    });

    it('returns all items for 1.0', function() {
      expect(item).toEqual('TestCTRL');
    });
  });
  describe('#type', function() {
    var item;
    beforeEach(function() {
      Documentation.type('2.0', 'testType').then(function(data) {
        item = data;
      });
      $scope.$apply();
    });

    it('returns all items for 1.0', function() {
      expect(item).toEqual('TestType');
    });
  });
});
