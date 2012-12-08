# Services

angular.module 'innerPeace.services', [], ($provide) ->
  $provide.factory "fancyMatcher", ->
    getInstance: -> new FancyMatcher
  $provide.factory "domSearcher", ["fancyMatcher", (fancyMatcher) ->
    getInstance: -> new DomSearcher fancyMatcher.getInstance()
  ]