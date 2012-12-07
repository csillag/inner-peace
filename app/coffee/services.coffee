# Services

angular.module('innerPeace.services', [])
  .service("fancyMatcher", diff_match_patch)
  .service("domSearcher", DomSearcher)

