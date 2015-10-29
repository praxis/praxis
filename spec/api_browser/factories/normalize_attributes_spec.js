describe('normalizeAttributes', function() {
  var normalizeAttributes;
  beforeEach(angular.mock.module('PraxisDocBrowser'));

  beforeEach(inject(function($rootScope, $injector) {
    normalizeAttributes = $injector.get('normalizeAttributes');
  }));

  var type = {
    attributes: {
      test1: {
        values: ['Hello'],
        irrelevantFlag: true
      },
      test2: {
        type: {
          attributes: {
            test3: {
              default: 'Yeah'
            },
            moreRecursive: {
              type: {
                attributes: {
                  test4: {}
                }
              }
            }
          }
        }
      }
    },
    example: {
      test1: 'Hello',
      test2: {
        test3: 'Yeah',
        moreRecursive: {
          test4: 3
        }
      }
    }
  };

  var expected = {
    test1: {
      options: {
        values: ['Hello'],
      }
    },
    test2: {
      options: {
      },
      type: {
        attributes: {
          test3: {
            options: {
              default: 'Yeah',
            }
          },
          moreRecursive: {
            options: {
            },
            type: {
              attributes: {
                test4: {
                  options: {
                  }
                }
              }
            }
          }
        }
      }
    }
  };

  expected = (function wrap(obj) { // this will wrap each object in objectContaining
    if (_.isObject(obj)) {
      return jasmine.objectContaining(_.mapValues(obj, wrap));
    }
    return obj;
  })(expected);


  it('normalizes attributes into options recursively', function() {
    normalizeAttributes(type, type.attributes);
    expect(type.attributes).toEqual(expected);
  });

  it('doesn\'t include irrelevant options', function() {
    expect(type.attributes.test1.options.irrelevantFlag).toBeUndefined();
  });
});
