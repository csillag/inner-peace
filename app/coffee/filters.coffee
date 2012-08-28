
# Filters

angular
  .module('myApp.filters', [])
  .filter('interpolate', 
    ['version', (version)->
      (text)->
        return String(text).replace(/\%VERSION\%/mg, version)
    ])