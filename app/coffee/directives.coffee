# Directives 


angular
  .module('innerPeace.directives', [])
  .directive('appVersion', ['version', (version)->
    (scope, elm, attrs)->
      elm.text(version)
  ])
