#Controllers

class SearchController
  this.$inject = ['$document', '$scope', '$timeout', '$http', 'domTextMatcher']
  constructor: ($document, $scope, $timeout, $http, domTextMatcher) ->

    $document.find("#help1").popover(html:true)
    $document.find("#help2").popover(html:true)

    $scope.cleanResults = ->
      @paths = []
      @mappings = []
      @canSearch = false
      @sr = null

    $scope.init = ->
      @domMatcher = domTextMatcher.getInstance()
      @sourceMode = "local"
      @foundAction = "hilite"
      @matchEngine = "fuzzy"
      @localSource = "This is <br /> a <i>   test    </i> <b>    text   </b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
      @atomicOnly = true
      @searchPos = 0
      @matchThreshold = 50
      @$watch 'sourceMode', (newValue, oldValue) =>
        @cleanResults()
        @renderSource = null
        switch @sourceMode
          when "local"
            @domMatcher.setRootId "rendered-dom"
            @sourceModeNeedsInput = true
            @sourceURL = null
            @searchTerm = "sex text"
            @searchPos = 0
            @matchDistance = 1000
            @searchDistinct = true
            @searchCaseSensitice = false
#            @render() #TODO: remove this, only for testing    
          when "page"
            @sourceModeNeedsInput = true
            @sourceURL = null        
            @domMatcher.setRealRoot()
            @checkPaths()
            @searchTerm = "very"
            @searchPos = 0
            @matchDistance = 1000
          when "sample1"
            @renderSource = null
            @sourceURL = "sample1.html"
            @sourceModeNeedsInput = false
            @searchTerm = "formal truth jiggles the brain"
            @searchPos = 1000
            @matchDistance = 10000
          when "sample2"
            @renderSource = null
            @sourceURL = "sample2.html"
            @sourceModeNeedsInput = false
            @searchTerm = "openness and innovation"
            @searchPos = 300000
            @matchDistance = 300000        
 
      window.dtm_frame_loaded = =>
        @domMatcher.setRootIframe("dtm-demo-article-box")
        @checkPaths()        

      # Scan the region as soon as it's specified  
      @$watch 'selectedPath', => @scanSelectedPath()

      # Execute select as the user types  
      @$watch 'searchTerm', => @search()
      @$watch 'matchEngine', => @search()
      @$watch 'searchCaseSensitive', => @search()
      @$watch 'searchDistinct', => if @matchEngine is "exact" then @search()
      @$watch 'matchDistance', => if @matchEngine is "fuzzy" then @search()
      @$watch 'searchPos', => if @matchEngine is "fuzzy" then @search()
      @$watch 'matchThreshold', => if @matchEngine is "fuzzy" then @search()
      @$watch 'foundAction', => if @singleMode then @moveMark 0 else @markAll()

    $scope.scanSelectedPath = ->
      unless @selectedPath? then return
      @scanTime = @domMatcher.prepareSearch @selectedPath, true
#      console.log "Scanned " + @selectedPath + " in " + @scanTime + " ms."
      @canSearch = true
      @search()

    $scope.checkPaths = ->
      # wait for the browser to render the DOM for the new HTML
      $timeout =>
        @paths = @domMatcher.getAllPaths()
        if @selectedPath is @paths[0].path
          @scanSelectedPath()
        else
          @selectedPath = @paths[0].path

    $scope.render = ->
      #this function is called from a child scope, so we can't replace $scope with @ here.     
      $scope.renderSource = @localSource
      $scope.cleanResults()
      $scope.checkPaths()

    $scope.distanceExplanation = """

  The following example is a classic dilemma.
        
  There are two potential matches, one is close to the expected location but contains a one character error, the other is far from the expected location but is exactly the pattern sought after:
   
  match_main(\"abc12345678901234567890abbc\", \"abc\", 26)
   
  Which result is returned (0 or 24) is determined by the MatchDistance property.
   
  An exact letter match which is 'distance' characters away from the fuzzy location would score as a complete mismatch. For example, a distance of '0' requires the match be at the exact location specified, whereas a threshold of '1000' would require a perfect match to be within 800 characters of the expected location to be found using a 0.8 threshold (see below).

  The larger MatchDistance is, the slower search may take to compute.
  """.replace /\n/g, "<br />"

    $scope.thresholdExplanation = """

  MatchThreshold determines the cut-off value for a valid match.
    
  If Match_Threshold is closer to 0, the requirements for accuracy increase. If Match_Threshold is closer to 100 then it is more likely that a match will be found. The larger Match_Threshold is, the slower search may take to compute.
  """.replace /\n/g, "<br />"

    $scope.search = ->
      if @sr? then @domMatcher.undoHighlight @sr        

      if @canSearch and @searchTerm
        switch @matchEngine
          when "exact" then @sr = @domMatcher.searchExact @searchTerm, @searchDistinct, @searchCaseSensitive
          when "regex" then @sr = @domMatcher.searchRegex @searchTerm, @searchCaseSensitive
          when "fuzzy" then @sr = @domMatcher.searchFuzzy @searchTerm, @searchPos, @searchCaseSensitive, @matchDistance, @matchThreshold / 100
          else @sr = null
        @markAll()
      else
        @sr = null

    $scope.myHL   

    $scope.markAll = ->
      unless @sr? then return
      @singleMode = false
      @domMatcher.undoHighlight @sr
      switch @foundAction
        when "hilite" then @domMatcher.highlight @sr, null
        when "select" then @domMatcher.select @sr

    $scope.moveMark = (diff) ->
      unless @sr? then return        
      len = @sr.matches.length
      if @singleMode
        i = @markIndex + diff
        i += len while i < 0
        i = i % len
      else
        i = 0
      @markIndex = i
      @singleMode = true
      @domMatcher.undoHighlight @sr
      switch @foundAction
        when "hilite" then @domMatcher.highlight @sr, null, @markIndex
        when "select" then @domMatcher.select @sr, @markIndex

    $scope.markForward = -> @moveMark 1
    $scope.markBackward = -> @moveMark -1

    $scope.init()

angular.module('domTextMatcherDemo.controllers', [])
  .controller('SearchController', SearchController)
