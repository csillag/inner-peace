#Controllers

class SearchController
  this.$inject = ['$scope', '$timeout', '$http', 'domSearcher']
  constructor: ($scope, $timeout, $http, domSearcher) ->

    $scope.cleanResults = ->
      @paths = []
      @mappings = []
      @canSearch = false
      @searchResults = null
      @detailedResults = null

    $scope.init = ->
      @domSearcher = domSearcher.getInstance()  
      @rootId = "rendered-dom" #this is ID of the DOM element we use for rendering the demo HTML
      @sourceMode = "local"
      @localSource = "This is <br /> a <i>test</i> <b>text</b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
      @atomicOnly = true
      @searchPos = 0
      @$watch 'sourceMode', (newValue, oldValue) =>
        @cleanResults()
        @renderSource = null
        switch @sourceMode
          when "local"
            @domSearcher.setRootId @rootId
            @sourceModeNeedsInput = true
            @searchTerm = "text text"
            @searchPos = 0
          when "page"
            @sourceModeNeedsInput = true
            @domSearcher.setRealRoot()
            @checkPathsDelayed()
            @searchTerm = "very"
            @searchPos = 0
          when "sample1"
            @sourceModeNeedsInput = false
            rq =
              method: 'GET'
              url: 'sample1.html'
            $http(rq).success (data, status, headers, config) =>
              @renderSource = data
              @searchTerm = "formal truth jiggles the brain"
              @searchPos = 1000
              @checkPathsDelayed()
            .error (data, status, headers, config) ->
              console.log "http.get failed"                
            


#            ($http.get 'samples/sample1.html')
#              .success (data) ->


#              .fail ->

                
          when "url"
            @renderSource = null
            @sourceModeNeedsInput = true
            @searchTerm = "text text"
            @searchPos = 0        

    $scope.init()

    $scope.checkPaths = ->
      @paths = @domSearcher.getAllPaths()
      @selectedPath = @paths[0]
      @canSearch = true

    $scope.checkPathsDelayed = ->
      # wait for the browser to render the DOM for the new HTML
      $timeout => @checkPaths()  

    $scope.render = ->
      @renderSource = @localSource
      @cleanResults()
      @checkPathsDelayed()

    $scope.search = ->
     sr = @domSearcher.search @selectedPath, @searchTerm, @searchPos
     if sr?
       @searchResults = if sr.found is @searchTerm then " (Exact match.)" else " (Found this: '" + sr.found + "')"
       @detailedResults = sr.nodes
     else
       @searchResults = "Pattern not found."
       @detailedResults = []


angular.module('innerPeace.controllers', [])
  .controller('SearchController', SearchController)
