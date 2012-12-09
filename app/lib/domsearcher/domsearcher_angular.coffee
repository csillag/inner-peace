angular.module 'domsearcher', ['dmp'], ($provide) ->
  $provide.factory "domSearcher", ["dmpMatcher", (dmpMatcher) ->
    getInstance: -> new DomSearcher dmpMatcher.getInstance()
  ]
