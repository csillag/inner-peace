# Filters

booleanCheckmark = (input) -> if input then '\u2713' else ''#'\u2718'
quoteHTML = (input) ->
  unless input? then throw new Error "Called quoteHTML with null input!"
  "'" + (input.replace /[ ]/g, "&nbsp;") + "'"

angular
  .module('domTextMatcherDemo.filters', [])
  .filter('booleanCheckmark', -> booleanCheckmark)
  .filter('quoteHTML', -> quoteHTML)