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
      @foundAction = "select"
      @localSource = "This is <br /> a <i>   test    </i> <b>    text   </b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
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
      #this function is called from a child scope, so we can't replace $scope with @ here.     
      $scope.renderSource = @localSource
      $scope.cleanResults()
      $scope.checkPaths()

    $scope.explainDistance = ->
      alert """

  The following example is a classic dilemma.

  There are two potential matches, one is close to the expected location but contains a one character error, the other is far from the expected location but is exactly the pattern sought after:
   
  match_main(\"abc12345678901234567890abbc\", \"abc\", 26)
   
  Which result is returned (0 or 24) is determined by the MatchDistance property.
   
  An exact letter match which is 'distance' characters away from the fuzzy location would score as a complete mismatch. For example, a distance of '0' requires the match be at the exact location specified, whereas a threshold of '1000' would require a perfect match to be within 800 characters of the expected location to be found using a 0.8 threshold (see below).

  The larger MatchDistance is, the slower search may take to compute.
  """

    $scope.explainThreshold = ->
      alert """

  MatchThreshold determines the cut-off value for a valid match.
    
  If Match_Threshold is closer to 0, the requirements for accuracy increase. If Match_Threshold is closer to 100 then it is more likely that a match will be found. The larger Match_Threshold is, the slower search may take to compute.
  """

    $scope.search = ->
      if @sr? then @domSearcher.undoHighlight @sr

      @sr = @domSearcher.search @selectedPath, @searchTerm, @searchPos, @matchDistance, @matchThreshold / 100
      if @sr?
        @searchResults = if @sr.exact then " (Exact match.)" else " (Found this: '" + @sr.found + "')"
        @detailedResults = @sr.nodes
        switch @foundAction
          when "hilite" then @domSearcher.highlight @sr, "hl"
          when "select" then @domSearcher.select @sr
      else
        @searchResults = "Pattern not found."
        @detailedResults = []

angular.module('innerPeace.controllers', [])
  .controller('SearchController', SearchController)
