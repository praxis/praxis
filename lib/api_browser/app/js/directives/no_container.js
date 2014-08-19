app.directive('noContainer', function() {
	return {
		restrict: 'A',
		link: function(scope, element, attrs){
			element.replaceWith(element.children());
		}
	};
});
