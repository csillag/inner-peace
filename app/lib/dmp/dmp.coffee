class window.DMPMatcher
  constructor: -> @dmp = new diff_match_patch

  _reverse: (text) -> text.split("").reverse().join ""

  # Use this to get the max allowed pattern length.
  # Trying to use a longer pattern will give an error.
  getMaxPatternLength: -> @dmp.Match_MaxBits

  # The following example is a classic dilemma.
  # There are two potential matches, one is close to the expected location
  # but contains a one character error, the other is far from the expected
  # location but is exactly the pattern sought after:
  # 
  # match_main("abc12345678901234567890abbc", "abc", 26)
  # 
  # Which result is returned (0 or 24) is determined by the
  # MatchDistance property.
  # 
  # An exact letter match which is 'distance' characters away
  # from the fuzzy location would score as a complete mismatch.
  # For example, a distance of '0' requires the match be at the exact
  # location specified, whereas a threshold of '1000' would require
  # a perfect match to be within 800 characters of the expected location
  # to be found using a 0.8 threshold (see below).
  #
  # The larger MatchDistance is, the slower search may take to compute.
  # 
  # This variable defaults to 1000.
  setMatchDistance: (distance) -> @dmp.Match_Distance = distance
  getMatchDistance: -> @dmp.Match_Distance

  # MatchThreshold determines the cut-off value for a valid match.
  #  
  # If Match_Threshold is closer to 0, the requirements for accuracy
  # increase. If Match_Threshold is closer to 1 then it is more likely
  # that a match will be found. The larger Match_Threshold is, the slower
  # search may take to compute.
  # 
  # This variable defaults to 0.5.
  setMatchThreshold: (threshold) -> @dmp.Match_Threshold = threshold
  getMatchThreshold: -> @dmp.Match_Threshold

  # Given a text to search, a pattern to search for and an
  # expected location in the text near which to find the pattern,
  # return the location which matches closest.
  # 
  # The function will search for the best match based on both the number
  # of character errors between the pattern and the potential match,
  # as well as the distance between the expected location and the
  # potential match.
  #
  # If no match is found, the function returns null.
  search: (text, pattern, expectedStartLoc = 0) ->
    unless text? then throw new Error "Can't search in null text!"
    unless pattern? then throw new Error "Can't search for null pattern!"
    unless expectedStartLoc >= 0 then throw new Error "Can't search at negavive indices!"

    pLen = pattern.length
    maxLen = @getMaxPatternLength()

    if pLen <= maxLen
      return @searchForSlice text, pattern, expectedStartLoc
    else
      startSlice = pattern.substr 0, maxLen
      startPos = @searchForSlice text, startSlice, expectedStartLoc
      if startPos?
        endSlice = pattern.substr pLen - maxLen, maxLen
        endLoc = startPos.start + pLen - maxLen
        endPos = @searchForSlice text, endSlice, endLoc
        if endPos?
          matchLen = endPos.end - startPos.start
          if pLen*0.5 <= matchLen <= pLen*1.5
            found = text.substr startPos.start, matchLen
            return {
              start: startPos.start
              end: endPos.end
              found: found
              exact: found is pattern    
            }
#          else
#            console.log "Sorry, matchLen (" + matchLen + ") is not between " + 0.5*pLen + " and " + 1.5*pLen
#        else
#          console.log "endSlice ('" + endSlice + "') not found"
#      else
#        console.log "startSlice ('" + startSlice + "') not found"

    null

  # ============= Private part ==========================================
  # You don't need to call the functions below this point manually

  searchForSlice: (text, slice, expectedStartLoc) ->

    startIndex = @dmp.match_main text, slice, expectedStartLoc
    if startIndex is -1 then return
        
    txet = @_reverse text
    nrettap = @_reverse slice
    expectedEndLoc = startIndex + slice.length
    expectedDneLoc = text.length - expectedEndLoc
    dneIndex = @dmp.match_main txet, nrettap, expectedDneLoc
    endIndex = text.length - dneIndex
    matchLength = endIndex - startIndex
    found = text.substr startIndex, matchLength

    result =
      start: startIndex
      end: endIndex
      found: found
      exact: found is slice
