class window.DomTextMapper
  constructor: ->
    @setRealRoot()
    @restrictToSerializable false

  # ===== Public methods =======

  # Switch the library into "serializable-only" mode.
  # If set to true, all public API calls will be restricted to return
  # strictly serializable data structures.
  # (References to DOM objects will be omitted.)
  restrictToSerializable: (value = true) -> @restricted = value

  # Consider only the sub-tree beginning with the given node.
  # 
  # This will be the root node to use for all operations.
  setRootNode: (rootNode) ->
    @rootWin = window     
    @pathStartNode = @rootNode = rootNode

  # Consider only the sub-tree beginning with the node whose ID was given.
  # 
  # This will be the root node to use for all operations.
  setRootId: (rootId) -> @setRootNode document.getElementById rootId

  # Use this iframe for operations.
  #
  # Call this when mapping content in an iframe.
  setRootIframe: (iframeId) ->
    iframe = window.document.getElementById iframeId
    unless iframe? then throw new Error "Can't find iframe with specified ID!"
    @rootWin = iframe.contentWindow
    unless @rootWin? then throw new Error "Can't access contents of the spefified iframe!"
    @rootNode = @rootWin.document
    @pathStartNode = @getBody()

  # Work with the whole DOM tree
  # 
  # (This is the default; you only need to call this, if you have configured
  # a different root earlier, and now you want to restore the default setting.)
  setRealRoot: ->
    @rootWin = window    
    @rootNode = document
    @pathStartNode = @getBody() 

  # Notify the library that the document has changed.
  # This means that subsequent calls can not safely re-use previously cached
  # data structures, so some calculations will be necessary again.
  #
  # The usage of this feature is not mandatorry; if not receiving change notifications,
  # the library will just assume that the document can change anythime, and therefore
  # will not assume any stability.
  documentChanged: ->
    @lastDOMChange = @timestamp()
    console.log "Registered document change."

  # The available paths which can be scanned
  #
  # An map is returned, where the keys are the paths, and the values are objects with the following fields:
  #   path: the valid path value
  #   node: reference to the DOM node
  #   content: the text content of the node, as rendered by the browser
  #   length: the length of the next content
  getAllPaths: ->
#    console.log "in getAllPaths"
    if @domStableSince @lastCollectedPaths
      # We have a valid paths structure!
#      console.log "We have a valid cache."
      return if @restricted then @cleanPaths else @allPaths

    console.log "No valid cache, will have to calculate getAllPaths."
    @saveSelection()
    @allPaths = @collectPathsForNode @pathStartNode
    @restoreSelection()
    @lastCollectedPaths = @timestamp()
    if @restricted
      @cleanPaths = {}
      for path, info of @allPaths
        cleanInfo = $.extend({}, info);
        delete cleanInfo.node
        @cleanPaths[path] = cleanInfo
      @cleanPaths
    else
      @allPaths

  # Return the default path
  getDefaultPath: -> @getPathTo @pathStartNode

  # Select the given path (for visual identification), and optionally scroll to it
  selectPath: (path, scroll = false) ->
    info = @allPaths[path]
    @selectNode info.node ? @lookUpNode info.path

  # Scan the given part of the document.
  # 
  # Creates  a list of mappings between the string indices
  # (as appearing in the displayed text) and the DOM elements.
  #
  # The "path" paremater specifies the sub-tree inside the DOM that should be scanned.
  # Must be an XPath expression, relative to the configured root node.
  # You can check for valid input values using the getAllPaths method above.
  #
  # If no path is given, the whole sub-tree is scanned,
  # starting with the configured root node.
  #
  # Nothing is returned; the following properties are populated:
  #
  #  mappings will contain the created mappings
  #  corpus will contain the text content of the selected path# 
  #  scannedPath will be set to the path
  scan: (path = null) ->
#    console.log "In scan"
    path ?= @getDefaultPath()
    if path is @scannedPath and @domStableSince @lastScanned
#      console.log "We have a valid cache. Returning instead of scanning."
      return
    console.log "Scanning path: " + path
    @getAllPaths()
    node = @allPaths[path].node
    @mappings = {}
    @saveSelection()        
    @collectStrings node, path, null, 0, 0
    @restoreSelection()
    @scannedPath = path
    @lastScanned = @timestamp()
    @corpus = @mappings[path].pathInfo.content
#    console.log "Corpus is: " + @corpus
    null

  getRangeForPath: (path) ->
    result = @mappings[path]
    if @restricted
      result = $.extend {}, result;
      result.pathInfo = $.extend {}, result.pathInfo
      delete result.pathInfo.node
    result

  # Get the matching DOM elements for a given set of text ranges
  # (Calles getMappingsForRange for each element in the givenl ist)
  getMappingsForRanges: (ranges, path = null) ->
#    console.log "Ranges:"
#    console.log ranges
    mappings = (for range in ranges
      mapping = @getMappingsForRange range.start, range.end, path
    )
#    console.log "Raw mappings:"
#    console.log mappings

    if @restricted
      mappings = (for mapping in mappings
        cleanMapping = $.extend {}, mapping
        delete cleanMapping.range
        cleanMapping.nodes = (for node in cleanMapping.nodes
          cleanNode = $.extend {}, node
          cleanNode.element = $.extend {}, cleanNode.element
          cleanNode.element.pathInfo = $.extend {}, cleanNode.element.pathInfo
          delete cleanNode.element.pathInfo.node
          cleanNode
        )
        cleanMapping
      )
#      console.log "Cleaned mappings:"
#      console.log mappings

    mappings

  # Get the matching DOM elements for a given text range
  # 
  # If the "path" argument is supplied, scan is called automatically.
  # (Except if the supplied path is the same as the last scanned path.)
  getMappingsForRange: (start, end, path = null) ->
#    console.log "Collecting matches for [" + start + ":" + end + "]"
    unless (start? and end?) then throw new Error "start and end is required!"    

    if path? then @scan path

    unless @scannedPath? then throw new Error "Can not run getMappingsFor() without existing mappings. Either supply a path to scan, or call scan() beforehand!"

    # Collect the matching mappings     
    matches = []
    for p, mapping of @mappings when mapping.atomic and @regions_overlap mapping.start, mapping.end, start, end
      do (mapping) =>
#        console.log "Checking " + mapping.pathInfo.path
#        console.log mapping
        match =
          element: mapping
        full_match = start <= mapping.start and mapping.end <= end
        if full_match 
          match.full = true
          match.wanted = mapping.content
        else
         if start <= mapping.start
            match.end = end - mapping.start
            match.wanted = mapping.pathInfo.content.substr 0, match.end                
          else if mapping.end <= end
            match.start = start - mapping.start
            match.wanted = mapping.pathInfo.content.substr match.start        
          else
            match.start = start - mapping.start
            match.end = end - mapping.start
            match.wanted = mapping.pathInfo.content.substr match.start, match.end - match.start
        @computeSourcePositions match
        match.yields = mapping.pathInfo.node.data.substr match.startCorrected, match.endCorrected - match.startCorrected
        matches.push match

    if matches.length is 0
      throw new Error "No matches found!"
        

    # Create a DOM range object
    r = @rootWin.document.createRange()
    startMatch = matches[0]
    startNode = startMatch.element.pathInfo.node
    startPath = startMatch.element.pathInfo.path
    startOffset = startMatch.startCorrected
    if startMatch.full
      r.setStartBefore startNode
      startInfo = startPath
    else
      r.setStart startNode, startOffset
      startInfo = startPath + ":" + startOffset

    endMatch = matches[matches.length - 1]
    endNode = endMatch.element.pathInfo.node
    endPath = endMatch.element.pathInfo.path
    endOffset = endMatch.endCorrected
    if endMatch.full
      r.setEndAfter endNode
      endInfo = endPath
    else
      r.setEnd endNode, endOffset
      endInfo = endPath + ":" + endOffset

    result = {
      nodes: matches
      range: r
      rangeInfo:
        startPath: startPath
        startOffset: startOffset
        startInfo: startInfo
        endPath: endPath
        endOffset: endOffset
        endInfo: endInfo
    }
#    console.log "Done collecting"
    result

  # ===== Private methods (never call from outside the module) =======

  timestamp: -> new Date().getTime()

  domChangedSince: (timestamp) ->
#    console.log "Has the DOM changed since " + timestamp + "?"
    if @lastDOMChange? and timestamp? then @lastDOMChange > timestamp else true
#    if @lastDOMChange? and timestamp?
#      console.log "We have a timestamp, checking..."
#      result = @lastDOMChange > timestamp
#      console.log result
#    else
#      console.log "We don't have a timestamp (or a reference), assuming it has changed."
#      true        

  domStableSince: (timestamp) -> not @domChangedSince timestamp

  getProperNodeName: (node) ->
    nodeName = node.nodeName
    switch nodeName
      when "#text" then return "text()"
      when "#comment" then return "comment()"
      when "#cdata-section" then return "cdata-section()"
      else return nodeName

  getPathTo: (node) ->
    xpath = '';
    while node != @rootNode
      pos = 0
      tempitem2 = node
      while tempitem2
        if tempitem2.nodeName is node.nodeName
          pos++
        tempitem2 = tempitem2.previousSibling

      xpath = (@getProperNodeName node) + (if pos>1 then "[" + pos + ']' else "") + '/' + xpath
      node = node.parentNode
    xpath = (if @rootNode.ownerDocument? then './' else '/') + xpath
    xpath = xpath.replace /\/$/, ''
    xpath

  collectPathsForNode: (node, results = {}) ->
    path = @getPathTo node
    cont = @getNodeContent node, false
    if cont.length then results[path] =
      path: path
      content: cont
      length: cont.length
      node : node
    
    if node.hasChildNodes
      children = node.childNodes
      i = 0
      while i < children.length
        @collectPathsForNode children[i], results
        i++
    results

  getBody: -> (@rootWin.document.getElementsByTagName "body")[0]

  regions_overlap: (start1, end1, start2, end2) -> start1 < end2 and start2 < end1

  lookUpNode: (path) ->
    doc = @rootNode.ownerDocument ? @rootNode
    results = doc.evaluate path, @rootNode, null, 0, null
    node = results.iterateNext()

  # save the original selection
  saveSelection: ->
    sel = @rootWin.getSelection()        
#    console.log "Saving selection: " + sel.rangeCount + " ranges."
    @oldRanges = (sel.getRangeAt i) for i in [0 ... sel.rangeCount]
    switch sel.rangeCount
      when 0 then @oldRanges ?= []
      when 1 then @oldRanges = [ @oldRanges ]

  # restore selection
  restoreSelection: ->
#    console.log "Restoring selection: " + @oldRanges.length + " ranges."
    sel = @rootWin.getSelection()
    sel.removeAllRanges()
    sel.addRange range for range in @oldRanges

  # Select the given node (for visual identification), and optionally scroll to it
  selectNode: (node, scroll = false) ->  
    sel = @rootWin.getSelection()

    # clear the selection
    sel.removeAllRanges()

    # create our range, and select it
    range = @rootWin.document.createRange()
    range.setStartBefore node
    range.setEndAfter node
    sel.addRange range
    if scroll
      sn = node
      while not sn.scrollIntoViewIfNeeded?
        sn = sn.parentNode
      sn.scrollIntoViewIfNeeded()
    sel

  # Read the "text content" of a sub-tree of the DOM by creating a selection from it
  getNodeSelectionText: (node, shouldRestoreSelection = true) ->
    if shouldRestoreSelection then @saveSelection()
        
    # select the node
    sel = @selectNode node

    # read (and convert) the content of the selection
    text = sel.toString().trim().replace(/\n/g, " ").replace /[ ][ ]+/g, " "

    if shouldRestoreSelection then @restoreSelection()
    text


  # Convert "display" text indices to "source" text indices.
  computeSourcePositions: (match) ->
#    console.log "In computeSourcePosition"
#    console.log match.element.pathInfo.path
#    console.log match.element.pathInfo.node.data

    # the HTML source of the text inside a text element.
    sourceText = match.element.pathInfo.node.data.replace /\n/g, " "
#    console.log "sourceText is '" + sourceText + "'"

    # what gets displayed, when the node is processed by the browser.
    displayText = match.element.pathInfo.content
#    console.log "displayText is '" + displayText + "'"

    # The selected range in displayText.
    displayStart = if match.start? then match.start else 0
    displayEnd = if match.end? then match.end else displayText.length
#    console.log "Display range is: " + displayStart + "-" + displayEnd

    sourceIndex = 0
    displayIndex = 0

    until sourceStart? and sourceEnd?
      sc = sourceText[sourceIndex]
      dc = displayText[displayIndex]
      if sc is dc
        if displayIndex is displayStart
          sourceStart = sourceIndex
        displayIndex++        
        if displayIndex is displayEnd
          sourceEnd = sourceIndex + 1

      sourceIndex++
    match.startCorrected = sourceStart
    match.endCorrected = sourceEnd
 #   console.log "computeSourcePosition done. Corrected range is: " + match.startCorrected + "-" + match.endCorrected
    null

  getNodeContent: (node, shouldRestoreSelection = true) -> @getNodeSelectionText node, shouldRestoreSelection

  collectStrings: (node, parentPath, parentContent = null, parentIndex = 0, index = 0) ->
#    console.log "Scanning path " + parentPath    
#    content = @getNodeContent node, false

    pathInfo = @allPaths[parentPath]
    content = pathInfo?.content

    if not content? or content is ""
      # node has no content            
#      console.log "No content, returning"
      return index
        
    startIndex = if parentContent? then (parentContent.indexOf content, index) else index
    if startIndex is -1
       # content of node is not present in parant's content - probably hidden, or something similar
#       console.log "Content is not present in parent, returning"
       return index


    endIndex = startIndex + content.length
    atomic = not node.hasChildNodes()
    @mappings[parentPath] =
      pathInfo: pathInfo
      start: parentIndex + startIndex
      end: parentIndex + endIndex
      atomic: atomic

    if not atomic
      children = node.childNodes
      i = 0
      pos = 0
      typeCount = Object()
      while i < children.length
        child = children[i]
        nodeName = @getProperNodeName child
        oldCount = typeCount[nodeName]
        newCount = if oldCount? then oldCount + 1 else 1
        typeCount[nodeName] = newCount
        childPath = parentPath + "/" + nodeName + (if newCount > 1 then "[" + newCount + "]" else "")
        pos=@collectStrings child, childPath, content, parentIndex + startIndex, pos
        i++

    endIndex

