// Use this to provide settings for the doc browser
app.provider('Configuration', function() {
  this.title = 'API Browser';
  this.versionLabel = 'API Version';
  this.expandChildren = true;

  this.$get = function() {
    return this;
  };
}).run(function(Configuration, $rootScope, $document) {
  _.extend($rootScope, _.omit(Configuration, '$get'));
  $document[0].title = Configuration.title;
});
