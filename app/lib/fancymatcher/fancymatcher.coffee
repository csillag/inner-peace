class window.FancyMatcher
  constructor: -> @dmp = new diff_match_patch

  _reverse: (text) -> text.split("").reverse().join ""

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

    startIndex = @dmp.match_main text, pattern, expectedStartLoc
    if startIndex > 0
      txet = @_reverse text
      nrettap = @_reverse pattern
      expectedEndLoc = startIndex + pattern.length
      expectedDneLoc = text.length - expectedEndLoc
      dneIndex = @dmp.match_main txet, nrettap, expectedDneLoc
      endIndex = text.length - dneIndex
      matchLength = endIndex - startIndex
      result =
        start: startIndex
        end: endIndex
        found: text.substr startIndex, matchLength
    else
      result = null

    result

