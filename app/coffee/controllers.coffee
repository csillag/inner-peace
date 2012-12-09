#Controllers

class BrowserController
  this.$inject = ['$scope', '$rootScope']
  constructor: ($scope, $rootScope) ->
    $rootScope.hasInnerText = document.getElementsByTagName("body")[0].innerText?
    if not $rootScope.hasInnerText
      $scope.message = "Unfortunately, your browser does not support innerText. Try this with Chrome[ium]."

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
      @rootId = "rendered-dom" #this is ID of the DOM element we use for rendering the demo HTML
      @sourceMode = "local"
      @localSource = "This is <br /> a <i>test</i> <b>text</b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
      @atomicOnly = true
      @searchPos = 0
      @maxPatternLength = @domSearcher.getMaxPatternLength()
      @matchDistance = 1000
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
          when "page"
            @sourceModeNeedsInput = true
            @domSearcher.setRealRoot()
            @checkPathsDelayed()
            @searchTerm = "very"
            @searchPos = 0
          when "sample1"
            @sourceModeNeedsInput = false
            $http.get("sample1.html").success (data) =>
              @renderSource = data
              @searchTerm = "formal truth jiggles the brain"
              @searchPos = 1000
              @checkPathsDelayed()

    $scope.init()

    $scope.checkPaths = ->
      @paths = @domSearcher.getAllPaths()
      @selectedPath = @paths[0].path
      @canSearch = true

    $scope.checkPathsDelayed = ->
      # wait for the browser to render the DOM for the new HTML
      $timeout => @checkPaths()  

    $scope.render = ->
      @renderSource = ""
      $timeout =>  
        @renderSource = @localSource
        @cleanResults()
        @checkPathsDelayed()

    $scope.search = ->
      @undoHilite()
      @sr = @domSearcher.search @selectedPath, @searchTerm, @searchPos, @matchDistance, @matchThreshold / 100
      if @sr?
        @searchResults = if @sr.found is @searchTerm then " (Exact match.)" else " (Found this: '" + @sr.found + "')"
        @detailedResults = @sr.nodes
        @domSearcher.highlight @sr
#        console.log @sr.undoHilite
      else
        @searchResults = "Pattern not found."
        @detailedResults = []

    $scope.undoHilite = ->
      if not @sr? then return  
      @domSearcher.undoHighlight @sr
      @sr = null

angular.module('innerPeace.controllers', [])
  .controller('SearchController', SearchController)
  .controller('BrowserController', BrowserController)
