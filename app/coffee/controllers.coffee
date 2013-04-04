#Controllers

class SearchController
  this.$inject = ['$document', '$scope', '$timeout', '$http', 'domTextMatcher', 'domTextHiliter']
  constructor: ($document, $scope, $timeout, $http, domTextMatcher, domTextHiliter) ->

    $document.find("#help1").popover(html:true)
    $document.find("#help2").popover(html:true)

    $scope.cleanResults = ->
      delete @mappings
      delete @sr
      delete @hlTask
      @canSearch = false

    $scope.init = ->
      @domMatcher = domTextMatcher.getInstance()
      @hiliter = domTextHiliter
#      @sourceMode = "sample2"
      @sourceMode = "local"
      @foundAction = "hilite"
      @matchEngine = "fuzzy"
      @localSource = "This is <br /> a <i>   test    </i> <b>    text   </b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
      @atomicOnly = true
      @searchPos = 0
      @matchThreshold = 50
      @$watch 'sourceMode', (newValue, oldValue) =>
        @cleanResults()
        delete @renderSource
        switch @sourceMode
          when "local"
            @domMatcher.setRootId "rendered-dom"
            @sourceModeNeedsInput = true
            delete @sourceURL
            @searchTerm = "sex text"
            @searchPos = 0
            @matchDistance = 1000
            @searchDistinct = true
            @searchCaseSensitice = false
#            @render() #TODO: remove this, only for testing    
          when "page"
            @sourceModeNeedsInput = true
            delete @sourceURL
            @domMatcher.setRealRoot()
            @dataChanged()
            @searchTerm = "very"
            @searchPos = 0
            @matchDistance = 1000
          when "sample1"
            delete @renderSource
            @sourceURL = "sample1.html"
            @sourceModeNeedsInput = false
            @searchTerm = "formal truth jiggles the brain"
            @searchPos = 1000
            @matchDistance = 10000
          when "sample2"
            delete @renderSource
            @sourceURL = "sample2.html"
            @sourceModeNeedsInput = false
            @searchTerm = "openness and innovation"
            @searchPos = 300000
            @matchDistance = 300000        
 
      window.dtm_frame_loaded = =>
        @domMatcher.setRootIframe("dtm-demo-article-box")
        @dataChanged()        

      # Execute select as the user types  
      @$watch 'searchTerm', => @search()
      @$watch 'matchEngine', => @search()
      @$watch 'searchCaseSensitive', => @search()
      @$watch 'searchDistinct', => if @matchEngine is "exact" then @search()
      @$watch 'matchDistance', => if @matchEngine is "fuzzy" then @search()
      @$watch 'searchPos', => if @matchEngine is "fuzzy" then @search()
      @$watch 'matchThreshold', => if @matchEngine is "fuzzy" then @search()
      @$watch 'foundAction', => if @singleMode then @moveMark 0 else @markAll()

    $scope.scanProgress = (progress) -> console.log "Scanning: " + progress

    $scope.dataChanged = ->
      # wait for the browser to render the DOM for the new HTML
      $timeout =>
        @domMatcher.documentChanged()
        @domMatcher.scan @scanProgress, (r) => @$apply =>
          @traverseTime = r.time
          @canSearch = true
          @search()        

    $scope.render = ->
      #this function is called from a child scope, so we can't replace $scope with @ here.     
      $scope.renderSource = @localSource
      $scope.cleanResults()
      $scope.dataChanged()

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
      @hiliter.undo @hlTask          

      if @canSearch and @searchTerm
        switch @matchEngine
          when "exact"
            @sr = @domMatcher.searchExact @searchTerm, @searchDistinct, @searchCaseSensitive
          when "regex"
            @sr = @domMatcher.searchRegex @searchTerm, @searchCaseSensitive
          when "fuzzy"
            options =
              matchDistance: @matchDistance,
              matchThreshold: @matchThreshold / 100
              withDiff: true
            @sr = @domMatcher.searchFuzzy @searchTerm, @searchPos, @searchCaseSensitive, null, options
          else delete @sr
        @markAll()
      else
        delete @s

    $scope.markAll = ->
      unless @sr? then return
      @singleMode = false
      @hiliter.undo @hlTask          
      switch @foundAction
        when "hilite" then @hlTask = @hiliter.highlightSearchResults @sr
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
      @hiliter.undo @hlTask
      switch @foundAction
        when "hilite" then @hlTask = @hiliter.highlightSearchResults @sr, null, @markIndex
        when "select" then @domMatcher.select @sr, @markIndex

    $scope.markForward = -> @moveMark 1
    $scope.markBackward = -> @moveMark -1

    $scope.init()

angular.module('domTextMatcherDemo.controllers', [])
  .controller('SearchController', SearchController)
