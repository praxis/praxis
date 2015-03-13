describe('Documentation service', function() {
  var $scope, Documentation, $httpBackend;

  beforeEach(angular.mock.module('PraxisDocBrowser'));

  beforeEach(inject(function($rootScope, $injector) {
    $scope = $rootScope.$new();
    Documentation = $injector.get('Documentation');
    $httpBackend = $injector.get('$httpBackend');
  }));

  afterEach(function() {
    $httpBackend.verifyNoOutstandingExpectation();
    $httpBackend.verifyNoOutstandingRequest();
  });

  describe('#getIndex', function() {
    var result, response = {
      '1.0': {
        'Blogs': {
          'controller': 'V1-Controllers-Blogs',
          'name': 'V1::Controllers::Blogs',
          'media_type': 'V1-MediaTypes-Blog'
        },
        'Posts': {
          'controller': 'V1-ResourceDefinitions-Posts',
          'name': 'V1::ResourceDefinitions::Posts',
          'media_type': 'V1-MediaTypes-Post'
        },
        'Users': {
          'controller': 'V1-ResourceDefinitions-Users',
          'name': 'V1::ResourceDefinitions::Users',
          'media_type': 'V1-MediaTypes-User'
        }
      }
    };
    beforeEach(function() {
      $httpBackend.expectGET('api/index.json').respond(response);
      Documentation.getIndex().then(function(data) {
        result = data;
      });
      $httpBackend.flush();
      $scope.$apply();
    });

    it('returns the index data', function() {
      expect(result.data).toEqual(response);
    });
  });
});
