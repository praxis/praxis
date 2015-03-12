app.directive('noContainer', function() {
	return {
		restrict: 'A',
		link: function(scope, element){
			element.replaceWith(element.children());
		}
	};
});
