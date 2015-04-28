describe('typePlaceholder', function() {
  var $scope, element, spy, fakeTemplate;
  beforeEach(angular.mock.module('PraxisDocBrowser', function($provide) {
    spy = jasmine.createSpy('templateFor').and.callFake(function() {
      return fakeTemplate();
    });
    $provide.value('templateFor', spy);
  }));

  beforeEach(inject(function($compile, $rootScope, $q) {
    fakeTemplate = function() {
      return $q.when($compile('<div>result = <span>{{type.name}}</div>'));
    };
    $scope = $rootScope.$new();
    $scope.type = {name: 'test'};
    element = $compile('<div><type-placeholder type="type" template="embedded"></type-placeholder></div>')($scope);
    $scope.$apply();
  }));

  it('calls template for', function() {
    expect(spy).toHaveBeenCalledWith($scope.type, 'embedded');
  });

  it('replaces itself', function() {
    expect(element.text()).toEqual('result = test');
  });
});
