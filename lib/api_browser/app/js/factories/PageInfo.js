app.service('PageInfo', function($rootScope) {
  this.title = null;
  var self = this;
  $rootScope.$watch(function() {
    return self.title;
  }, function() {
    $rootScope.subtitle = self.title;
  });
});
