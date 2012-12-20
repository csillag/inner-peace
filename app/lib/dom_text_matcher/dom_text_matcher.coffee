class window.DomTextMatcher

  # ===== Public methods =======

  # Consider only the sub-tree beginning with the given node.
  # 
  # This will be the root node to use for all operations.
  setRootNode: (rootNode) -> @mapper.setRootNode rootNode

  # Consider only the sub-tree beginning with the node whose ID was given.
  # 
  # This will be the root node to use for all operations.
  setRootId: (rootId) -> @mapper.setRootId rootId

  # Use this iframe for operations.
  #
  # Call this when mapping content in an iframe.
  setRootIframe: (iframeId) -> @mapper.setRootIframe iframeId
        
  # Work with the whole DOM tree
  # 
  # (This is the default; you only need to call this, if you have configured
  # a different root earlier, and now you want to restore the default setting.)
  setRealRoot: -> @mapper.setRealRoot()

  # The available paths which can be searched
  # 
  # An array is returned, with each entry containing a "path" and a "length" field.
  # The value of the "path" field is the valid path value, "length" contains information
  # about the length of content belonging to the given path.
  getAllPaths: -> @mapper.getAllPaths()

  # Prepare for searching the specified path
  # 
  # Returns the time (in ms) it took the scan the specified path
  prepareSearch: (path, rescan = false) ->
    t0 = @timestamp()    
    @mapper.scan path, rescan
    t1 = @timestamp()
    t1 - t0

  # Search for text using exact string matching
  #
  # Parameters:
  #  pattern: what to search for
  #
  #  distinct: forbid overlapping matches? (defaults to true)
  #
  #  caseSensitive: should the search be case sensitive? (defaults to false)
  # 
  #  path: the sub-tree inside the DOM you want to search.
  #    Must be an XPath expression, relative to the configured root node.
  #    You can check for valid input values using the getAllPaths method above.
  #    It's not necessary to submit path, if the search was prepared beforehand,
  #    with the prepareSearch() method
  # 
  #  rescan: should the DOM be re-scanned, even if we already have a mapping for it?
  # 
  # For the details about the returned data structure, see the documentation of the search() method.
  searchExact: (pattern, distinct = true, caseSensitive = false, path = null, rescan = false) ->
    if not @pm then @pm = new window.DTM_ExactMatcher
    @pm.setDistinct(distinct)
    @pm.setCaseSensitive(caseSensitive)
    @search(@pm, pattern, null, path, rescan)

  # Search for text using regular expressions
  #
  # Parameters:
  #  pattern: what to search for
  #
  #  caseSensitive: should the search be case sensitive? (defaults to false)
  # 
  #  path: the sub-tree inside the DOM you want to search.
  #    Must be an XPath expression, relative to the configured root node.
  #    You can check for valid input values using the getAllPaths method above.
  #    It's not necessary to submit path, if the search was prepared beforehand,
  #    with the prepareSearch() method
  # 
  #  rescan: should the DOM be re-scanned, even if we already have a mapping for it?
  # 
  # For the details about the returned data structure, see the documentation of the search() method.
  searchRegex: (pattern, caseSensitive = false, path = null, rescan = false) ->
    if not @rm then @rm = new window.DTM_RegexMatcher
    @rm.setCaseSensitive(caseSensitive)
    @search(@rm, pattern, null, path, rescan)

  # Search for text using fuzzy text matching
  #
  # Parameters:
  #  pattern: what to search for
  #
  #  pos: where to start searching
  #
  #  caseSensitive: should the search be case sensitive? (defaults to false)
  # 
  #  matchDistance and
  #  matchThreshold:
  #     fine-tuning parameters for the d-m-p library.
  #     See http://code.google.com/p/google-diff-match-patch/wiki/API for details.
  # 
  #  path: the sub-tree inside the DOM you want to search.
  #    Must be an XPath expression, relative to the configured root node.
  #    You can check for valid input values using the getAllPaths method above.
  #    It's not necessary to submit path, if the search was prepared beforehand,
  #    with the prepareSearch() method
  # 
  #  rescan: should the DOM be re-scanned, even if we already have a mapping for it?
  # 
  # For the details about the returned data structure, see the documentation of the search() method.
  searchFuzzy: (pattern, pos, caseSensitive = false, matchDistance = 1000, matchThreshold = 0.5, path = null, rescan = false) ->
    if not @dmp? then @dmp = new window.DTM_DMPMatcher
    @dmp.setMatchDistance matchDistance
    @dmp.setMatchThreshold matchThreshold
    @dmp.setCaseSensitive caseSensitive
    @search(@dmp, pattern, pos, path, rescan)

  # Call this to select the search results
  #
  # Parameters:
  #   "indices" is an (optional) array of match numbers to select.
  #   It can be a single number, or a list, or ommitted to select all.
  select: (results, indices = null) ->
    unless results? then return
    len = results.matches.length
    if indices?
      if typeof indices is 'number' then indices = [indices]
    else
       indices = [0 ... len]
    sel = window.getSelection()
    sel.removeAllRanges()
#    (sel.addRange results.matches[index].range) for index in indices when 0 <= index < len
    for index in indices when 0 <= index < len
      do (index) =>
        match = results.matches[index]
        sel.addRange match.range


  # Parameters:
  #   "hiliteTemplate" is a DOM node to use for wrapper for higlighting.
  #     (strong, b, i, emph, span with a class, etc can all work.)
  #     should be an actual DOM node, created by document.createElement()
  # 
  #   "indices" is an (optional) array of match numbers to select.
  #   It can be a single number, or a list, or ommitted to select all.
  highlight: (results, hiliteTemplate = null, indices = null) ->

    hiliteTemplate ?= @standardHilite

    len = results.matches.length
    if indices?
      if typeof indices is 'number' then indices = [indices]
    else
      if len
        indices = [0 ... len]
      else
         return

    # Prepare data structures for undo   
    toInsert = []
    toRemove = []

    # Collect all matching mappings for hilite, and group them by path
    hilitePaths = {}
    for index in indices
      do (index) =>
        if not (0 <= index < len)
          console.log "Warning: match #" + index + " does not exist! (Allowed: [" + index + " - " + (len-1) + "])"
        else
#          console.log "Highlighting match #" + index
          for match in results.matches[index].nodes
            do (match) =>
              path = match.element.path
              hilitePaths[path] ?= []
              hilitePaths[path].push match
 
    # Now do the highlighting
    for path, matches of hilitePaths
      do (path, matches) =>
        node = matches[0].element.node
        # Calculate a normalized set of ranges 
        ranges = @uniteRanges ({start: match.startCorrected, end: match.endCorrected } for match in matches)
        clone = node.cloneNode()
        match.element.node = clone for match in matches

        len = node.data.length
        full = ranges.length is 1 and ranges[0].start is 0 and ranges[0].end is len
        if full
          # easy to do, can highlight full element
          hl = @hilite node, hiliteTemplate
          toInsert.push
            node: clone
            before: hl
          toRemove.push hl
        else
            # Unfortunately, we need to mess around the insides of this element
            index = 0
            firstRegion = true
            nextPart = node
            for range in ranges
              do (range) =>
                if range.start is 0
                  # This is the first range, and it starts at the start of the node      
                  nextPart = nextPart.splitText range.end
                  firstPart = nextPart.previousSibling
                  hl = @hilite firstPart, hiliteTemplate
                  toInsert.push
                    node: clone
                    before: hl
                  toRemove.push hl
                  index = range.end - 1
                else if range.end is len
                  # this is the last range, and it ends at the end of the node
                  lastPart = nextPart.splitText range.start - index
                  nextPart = null
                  remainingPart = lastPart.previousSibling
                  hl = @hilite lastPart, hiliteTemplate
                  if firstRegion then toInsert.push
                    node: clone
                    before: remainingPart
                  toRemove.push remainingPart
                  toRemove.push hl
                else
                  # this range is is at the middle of the node
                  middlePart = nextPart.splitText range.start - index
                  beforePart = middlePart.previousSibling
                  nextPart = middlePart.splitText range.end - range.start
                  hl = @hilite middlePart, hiliteTemplate
                  if firstRegion then toInsert.push
                    node: clone
                    before: beforePart
                  toRemove.push beforePart
                  toRemove.push hl
                  index = range.end - 1
                firstRange = false
            if nextPart? then toRemove.push nextPart                

    results.undoHilite =
      insert: toInsert
      remove: toRemove

  # Call this to undo highlighting search results
  #
  # It's your responsibility to only call this if a highlight is at place.
  # (Altought calling it more than once will do no harm.)
  # Pass in the searchResult that was used with the highlighting.
  undoHighlight: (searchResult) ->
    unless searchResult.undoHilite? then return
    insert.before.parentNode.insertBefore insert.node, insert.before for insert in searchResult.undoHilite.insert
    remove.parentNode.removeChild remove for remove in searchResult.undoHilite.remove
    searchResult.undoHilite = null
  
        
  # ===== Private methods (never call from outside the module) =======

  constructor: (domTextMapper) ->
    @mapper = domTextMapper
    hl = document.createElement "span"
    hl.setAttribute "style", "background-color: yellow; color: black; border-radius: 3px; box-shadow: 0 0 2px black;"
    @standardHilite = hl

  # Search for text with a custom matcher object
  #
  # Parameters:
  #  matcher: the object to use for doing the plain-text part of the search
  #  path: the sub-tree inside the DOM you want to search.
  #    Must be an XPath expression, relative to the configured root node.
  #    You can check for valid input values using the getAllPaths method above.
  #  pattern: what to search for
  #  pos: where do we expect to find it
  #
  # A list of matches is returned.
  # 
  # , each element with "start", "end", "found" and "nodes" fields.
  # start and end specify where the pattern was found; "found" is the matching slice.
  # Nodes is the list of matching nodes, with details about the matches.
  # 
  # If no match is found, null is returned.  # 
  search: (matcher, pattern, pos, path = null, rescan = false) ->
    # Prepare and check the pattern 
    unless pattern? then throw new Error "Can't search for null pattern!"
    pattern = pattern.trim()
    unless pattern? then throw new Error "Can't search an for empty pattern!"

    # Do some preparation, if required
    t0 = @timestamp()# 
    if path? then @prepareSearch(path, rescan)
    t1 = @timestamp()

    # Check preparations    
    unless @mapper.corpus? then throw new Error "Not prepared to search! (call PrepareSearch, or pass me a path)"

    # Do the text search
    textMatches = matcher.search @mapper.corpus, pattern, pos
    t2 = @timestamp()

    # Collect the mappings

    # Should work like a comprehension, but  it does not. WIll fix later.
    # matches = ($.extend {}, match, @mapper.getMappingsFor match.start, match.end) for match in textMatches

    matches = []
    for match in textMatches
      do (match) =>
        matches.push $.extend {}, match, @analyzeMatch(pattern, match), @mapper.getMappingsFor(match.start, match.end)
    t3 = @timestamp()
    return {
      matches: matches
      time:
        phase0_domMapping: t1 - t0
        phase1_textMatching: t2 - t1
        phase2_matchMapping: t3 - t2
        total: t3 - t0
    }

  hilite: (node, template) ->
    parent = node.parentNode
    unless parent?
      console.log "Warning: hilited node has no parent!"
      console.log node
      return
    window.wtft = template
    hl = template.cloneNode()
    hl.appendChild node.cloneNode()
    node.parentNode.insertBefore hl, node
    node.parentNode.removeChild node        
    hl    

  timestamp: -> new Date().getTime()

  analyzeMatch: (pattern, match) ->
    found = @mapper.corpus.substr match.start, match.end-match.start
    return {
      found: found
      exact: found is pattern
    }

  compareRanges: (a,b) ->
      if a.start < b.start
        return -1
      else if a.start > b.start
        return 1
      else if a.end < b.end
        return -1
      else if a.end > b.end
        return 1
      else
        return 0

  uniteRanges: (ranges) ->
    united = []
    lastRange = null
    for range in ranges.sort @compareRanges
      do (range) =>
        if lastRange? and lastRange.end >= range.start - 1
          # there was a previous range, and we can continue it
          if range.end > lastRange.end then lastRange.end = range.end
        else
          # no previous range, or it's too far off
          united.push lastRange =
            start: range.start
            end: range.end
    united

