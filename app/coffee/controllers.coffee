#Controllers

class SearchController
  this.$inject = ['$scope', '$timeout', '$http', 'domSearcher']
  constructor: ($scope, $timeout, $http, domSearcher) ->

    $scope.cleanResults = ->
      @paths = []
      @mappings = []
      @canSearch = false
      @sr = null  
      @searchResults = null
      @detailedResults = null

    $scope.init = ->
      @domSearcher = domSearcher.getInstance()
      @compatibility = @domSearcher.testBrowserCompatibility()
      @rootId = "rendered-dom" #this is ID of the DOM element we use for rendering the demo HTML
      @sourceMode = "local"
      @localSource = "This is <br /> a <i>   test    </i> <b>    te   xt   </b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
      @atomicOnly = true
      @searchPos = 0
      @maxPatternLength = @domSearcher.getMaxPatternLength()
      @matchThreshold = 50
      @$watch 'sourceMode', (newValue, oldValue) =>
        @cleanResults()
        @renderSource = null
        switch @sourceMode
          when "local"
            @domSearcher.setRootId @rootId
            @sourceModeNeedsInput = true
            @searchTerm = "sex text"
            @searchPos = 0
            @matchDistance = 1000
          when "page"
            @sourceModeNeedsInput = true
            @domSearcher.setRealRoot()
            @checkPaths()
            @searchTerm = "very"
            @searchPos = 0
            @matchDistance = 1000
          when "sample1"
            @sourceModeNeedsInput = false
            $http.get("sample1.html").success (data) =>
              @renderSource = data
              @searchTerm = "formal truth jiggles the brain"
              @searchPos = 1000
              @matchDistance = 10000
              @checkPaths()

    $scope.init()

    $scope.checkPaths = ->
      # wait for the browser to render the DOM for the new HTML
      $timeout =>
        @paths = @domSearcher.getAllPaths()
        @selectedPath = @paths[0].path
        @canSearch = true

    $scope.render = ->
      @renderSource = ""
      $timeout =>  
        @renderSource = @localSource
        @cleanResults()
        @checkPaths()

    $scope.search = ->
      if @sr? then @domSearcher.undoHighlight @sr

      @sr = @domSearcher.search @selectedPath, @searchTerm, @searchPos, @matchDistance, @matchThreshold / 100
      if @sr?
        @searchResults = if @sr.exact then " (Exact match.)" else " (Found this: '" + @sr.found + "')"
        @detailedResults = @sr.nodes
        @domSearcher.highlight @sr
      else
        @searchResults = "Pattern not found."
        @detailedResults = []

angular.module('innerPeace.controllers', [])
  .controller('SearchController', SearchController)
