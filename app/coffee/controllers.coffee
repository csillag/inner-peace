#Controllers

class SearchController
  this.$inject = ['$scope', '$timeout', '$filter', 'domSearcher']
  constructor: ($scope, $timeout, $filter, domSearcher) ->

    $scope.init = ->
      @domSearcher = domSearcher.getInstance()  
      @rootId = "rendered-dom" #this is ID of the DOM element we use for rendering the demo HTML
      @sourceMode = "local"
      @localSource = "This is <br /> a <i>test</i> <b>text</b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
      @atomicOnly = true
      @searchTerm = "text text"
      @searchPos = 0
      @$watch 'sourceMode', (newValue, oldValue) =>
        @paths = []
        @mappings = []
        @searchResults = null
        switch @sourceMode
          when "local"
            console.log "Source mode is now local."        
          when "page"
            @renderSource = null
            $timeout -> @checkPage()
          when "url"
            @renderSource = null        

    $scope.init()

    $scope.render = ->
      @renderSource = @localSource
      @paths = []
      @mappings = []
      @searchResults = null
      # wait for the browser to render the DOM for the new HTML
      $timeout => @checkRendered()

    $scope.checkRendered = ->
      @paths = @domSearcher.collectSubPaths @rootId, @rootId
      @selectedPath = @paths[0]

    $scope.checkPage = ->
      @paths = @domSearcher.collectPaths()
      @selectedPath = @paths[0]

    $scope.scan = ->
      switch @sourceMode
        when "local"
          @corpus = @domSearcher.getPathInnerText @selectedPath, @rootId
          @mappings = @domSearcher.collectContents @selectedPath, @rootId
          @searchResults = null
        when "page"
          @corpus = @domSearcher.getBodyInnerText()
          @mappings = @domSearcher.collectContents @selectedPath
          @searchResults = null        
        else
          alert "Not supported"

    $scope.search = ->
      searchResult = @domSearcher.search @corpus, @searchTerm, @searchPos
      if searchResult?
        startIndex = searchResult.start
        endIndex = searchResult.end
        matchLength = endIndex - startIndex
        match = @corpus.substr startIndex, matchLength
        @searchResults = "Match found at position [" + startIndex + ":" + endIndex + "]." + if match is @searchTerm then " (Exact match.)" else " (Found this: '" + match + "')"
        @detailedResults = @domSearcher.collectElements @mappings, startIndex, endIndex
      else
        @searchResults = "No match."
        @detailedResults = []
        
#      switch @sourceMode
#        when "local"
#
#        when "page"
#          alert "Not supported"
#        else
#          alert "Not supported"

angular.module('innerPeace.controllers', [])
  .controller('SearchController', SearchController)
