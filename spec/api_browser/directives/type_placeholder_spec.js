describe('typePlaceholder', function() {
  describe('basic operation', function() {
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
      element = $compile('<div><type-placeholder type=type template=embedded></type-placeholder></div>')($scope);
      $scope.$apply();
    }));

    it('calls template for', function() {
      expect(spy).toHaveBeenCalledWith($scope.type, 'embedded');
    });

    it('replaces itself', function() {
      expect(element.text()).toEqual('result = test');
    });
  });

  describe('actual rendering', function() {
    var $scope, element;

    function rowLooksLike(n, vals) {
      return function() {
        var row = element.find('table tr').eq(n).children();
        _.each(vals, function(val, i) {
          if (_.isString(val)) {
            expect(row.eq(i).text()).toEqual(val);
          } else {
            expect(row.eq(i).text()).toMatch(val);
          }
        });
        expect(row.length).toBe(vals.length);
      };
    }

    beforeEach(angular.mock.module('PraxisDocBrowser'));

    describe('standalone', function() {
      beforeEach(inject(function($compile, $rootScope) {
        $scope = $rootScope.$new();
        $scope.type = { // TODO figure out how to exercise the entire app
          name: 'Struct',
          attributes: {
            view: {
              options: {
                default: 'default',
                example: '"default"'
              },
              type: {
                name: 'String'
              }
            }
          }
        };
        element = $compile('<div><type-placeholder type="type" template="standalone" details="type.attributes"></type-placeholder></div>')($scope);
        $scope.$apply();
      }));

      it('renders out a table', function() {
        expect(element.find('table').length).toBe(1);
      });

      it('displays table headings', rowLooksLike(0,
        ['Attribute', 'Type', 'Description']
      ));

      it('displays an optional heading', rowLooksLike(1,
        ['Optional']
      ));

      it('has a table row for the attribute', rowLooksLike(2,
        ['view', 'String', /default.*default.*example.*"default"/mi]
      ));
    });

    describe('embedded', function() {
      var compile;
      beforeEach(inject(function($compile, $rootScope) {
        $scope = $rootScope.$new();
        compile = $compile('<div><table><tr type-placeholder type="item.type" template="embedded" details="item" name="item.name"></tr></table></div>');
      }));

      describe('struct', function() {
        beforeEach(function() {
          $scope.item = { // TODO figure out how to exercise the entire app
            type: {
              name: 'Struct',
              attributes: {
                view: {
                  options: {
                    default: 'default',
                    example: '"default"'
                  },
                  type: {
                    name: 'String'
                  }
                }
              }
            },
            name: 'Test1',
            description: 'Heading'
          };
          element = compile($scope);
          $scope.$apply();
        });

        it('renders out a table', function() {
          expect(element.find('table').length).toBe(1);
        });

        it('displays a row fow the type', rowLooksLike(0,
          ['Test1', 'Struct', /Heading/]
        ));

        it('displays a row for the subattribute', rowLooksLike(1,
          ['Test1.view', 'String', /default.*default.*example.*"default"/mi]
        ));
      });
    });
  });
});
