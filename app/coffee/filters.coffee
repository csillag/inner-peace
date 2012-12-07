
# Filters

booleanCheckmark = (input) -> if input then '\u2713' else ''#'\u2718'

angular
  .module('innerPeace.filters', [])
  .filter('interpolate', 
    ['version', (version)->
      (text)->
        return String(text).replace(/\%VERSION\%/mg, version)
    ])
  .filter('booleanCheckmark', -> booleanCheckmark)