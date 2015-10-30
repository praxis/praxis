app.directive('menuItem', function($compile, $stateParams) {

  function checkIfShouldShow(scope, params) {
    var currentId = params.action ? params.controller + '_action_' + params.action : (params.controller || params.type || params.trait);
    scope.isActive = scope.link.id === currentId;

    function checkLink(link) {
      if (link.id === currentId || link.parent === currentId) {
        return true;
      } else {
        if (link.parentRef) {
          var matches = function(r) { return r.id === currentId; };
          if (!link.isAction) {
            if ((link.parentRef.childResources || []).some(matches)) return true;
          }
          if ((link.parentRef.actions || []).some(matches)) return true;
        }

        return (link.childResources || []).some(checkLink) || (link.actions || []).some(checkLink);
      }
    }
    scope.shouldShow = scope.toplevel || checkLink(scope.link);
  }

  function link(scope) {
    scope.$on('$stateChangeSuccess', function(e, state, params) {
      checkIfShouldShow(scope, params);
    });
    checkIfShouldShow(scope, $stateParams);
  }

  return {
    restrict: 'E',
    templateUrl: 'views/directives/menu_item.html',
    scope: {
      link: '=',
      toplevel: '='
    },
    // hackery to make a recursive directive
    compile: function(element) {
      var contents = element.contents().remove();
      var compiledContents;
      return {
        post: function(scope, element){
          // Compile the contents
          if(!compiledContents) {
            compiledContents = $compile(contents);
          }
          // Re-add the compiled contents to the element
          compiledContents(scope, function(clone) {
            element.append(clone);
          });

          link(scope, element);
        }
      };
    }
  };
});
