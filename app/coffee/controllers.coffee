#Controllers

class SearchController
  this.$inject = ['$scope', '$timeout', '$filter', 'domSearcher', 'fancyMatcher']
  constructor: ($scope, $timeout, $filter, domSearcher, fancyMatcher) ->

    $scope.rootId = "rendered-dom" #this is ID of the DOM element we use for rendering the demo HTML
    $scope.sourceMode = "local"
    $scope.localSource = "This is <br /> a <i>test</i> <b>text</b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
    $scope.atomicOnly = true
    $scope.searchTerm = "text text"
    $scope.searchPos = 0

    $scope.$watch 'sourceMode', (newValue, oldValue) ->
      $scope.paths = []
      $scope.mappings = []
      $scope.searchResults = null

      if $scope.sourceMode == "local"
      else
        $scope.renderSource = null
        if $scope.sourceMode == "page"
          $timeout -> $scope.checkPage()
        else
        
    $scope.render = ->
      $scope.renderSource = $scope.localSource
      $scope.paths = []
      $scope.mappings = []
      $scope.searchResults = null

      # wait for the browser to render the DOM for the new HTML
      $timeout ->
        $scope.paths = domSearcher.collectSubPaths $scope.rootId, $scope.rootId
        $scope.selectedPath = $scope.paths[0]

    $scope.checkPage = ->
      $scope.paths = domSearcher.collectPaths()
      $scope.selectedPath = $scope.paths[0]

    $scope.scan = ->
      switch $scope.sourceMode
        when "local"
          $scope.corpus = domSearcher.getPathInnerText $scope.selectedPath, $scope.rootId
          $scope.mappings = domSearcher.collectContents $scope.selectedPath, $scope.rootId
          $scope.searchResults = null
        when "page"
          $scope.mappings = domSearcher.collectContents $scope.selectedPath
          $scope.searchResults = null        
        else
          alert "Not supported"

    $scope.search = ->
      switch $scope.sourceMode
        when "local"
#          console.log "Corpus is: " + $scope.corpus
#          console.log "Search term is: " + $scope.searchTerm
#          console.log "Search position is: " + $scope.searchPos
          startIndex = fancyMatcher.match_main $scope.corpus, $scope.searchTerm, $scope.searchPos
          if startIndex > -1
            matchLength = $scope.searchTerm.length
            match = $scope.corpus.substr startIndex, matchLength
            $scope.searchResults = "Match found at position #" + startIndex + "." + if match is $scope.searchTerm then " (Exact match.)" else " (Found this: '" + match + "')"
            $scope.detailedResults = domSearcher.collectElements $scope.mappings, startIndex, startIndex + matchLength
          else
            $scope.searchResults = "No match."
        when "page"
          alert "Not supported"
        else
          alert "Not supported"

angular.module('innerPeace.controllers', [])
  .controller('SearchController', SearchController)
