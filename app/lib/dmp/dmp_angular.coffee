angular.module 'dmp', [], ($provide) ->
  $provide.factory "dmpMatcher", -> getInstance: -> new DMPMatcher
