
# Filters

booleanCheckmark = (input) -> if input then '\u2713' else ''#'\u2718'
quoteHTML = (input) -> "'" + (input.replace /[ ]/g, "&nbsp;") + "'"

angular
  .module('innerPeace.filters', [])
  .filter('interpolate', 
    ['version', (version)->
      (text)->
        return String(text).replace(/\%VERSION\%/mg, version)
    ])
  .filter('booleanCheckmark', -> booleanCheckmark)
  .filter('quoteHTML', -> quoteHTML)