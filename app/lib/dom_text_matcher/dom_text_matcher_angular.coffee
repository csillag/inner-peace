angular.module('domTextMatcher', ['domTextMapper'])
  .factory("domTextMatcher", ["domTextMapper", (domTextMapper) ->
    getInstance: -> new DomTextMatcher domTextMapper.getInstance()
  ])
  .factory "domTextHiliter", -> new DomTextHiliter
