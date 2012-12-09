# Services

angular.module 'innerPeace.services', ["dmp"], ($provide) ->
  $provide.factory "domSearcher", ["dmpMatcher", (dmpMatcher) ->
    getInstance: -> new DomSearcher dmpMatcher.getInstance()
  ]