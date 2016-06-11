describe('attributeName filter', function() {
  var filter;
  beforeEach(angular.mock.module('PraxisDocBrowser'));

  beforeEach(inject(function(attributeNameFilter, $sce) {
    filter = function(input) {
      return $sce.getTrusted('html', attributeNameFilter(input));
    };
  }));

  it('only modifies input with one or more dots', function() {
    expect(function(str) {
      var dotsCount = str.split('.').length - 1;
      if (dotsCount === 0) {
        return str === filter(str);
      }
    }).forAll(qc.string);
  });

  it('adds a tag to the prefix', function() {
    expect(filter('ns.test')).toEqual('<span class="attribute-prefix">ns.</span>test');
  });
});
