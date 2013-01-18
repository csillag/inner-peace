class window.DomTextMapper
  constructor: ->
    @setRealRoot()

  # ===== Public methods =======

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

  # The available paths which can be scanned
  # 
  # An map is returned, where the keys are the paths, and the values are objects with the following fields:
  #   path: the valid path value
  #   node: reference to the DOM node
  #   content: the text content of the node, as rendered by the browser
  #   length: the length of the next content
  getAllPaths: ->
    @saveSelection()
    @allPaths = @collectPathsForNode @pathStartNode
    @restoreSelection()
    @allPaths

  # Return the default path
  getDefaultPath: -> @getPathTo @pathStartNode

  # Select the given path (for visual identification), and optionally scroll to it
  selectPath: (path, scroll = false) -> @selectNode @allPaths[path].node, scroll

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
  # The "rescan" parameter specifies whether the scan should be run again
  # even if the specified region is the same one that has been scanned
  # the last time.
  #
  # Nothing is returned; the following properties are populated:
  #
  #  mappings will contain the created mappings
  #  corpus will contain the text content of the selected path# 
  #  scannedPath will be set to the path
  scan: (path = null, rescan = false) ->
    path ?= @getDefaultPath()
    if path is @scannedPath and not rescan then return
#    console.log "Scanning path: " + path
    node = @allPaths[path].node
    @mappings = {}
    @saveSelection()        
    @collectStrings node, path, null, 0, 0
    @restoreSelection()
    @scannedPath = path
    @corpus = @mappings[path].pathInfo.content
#    console.log "Corpus is: " + @corpus
    null

  getRangeForPath: (path) -> @mappings[path]

  # Get the matching DOM elements for a given text range
  # 
  # If the "path" argument is supplied, scan is called automatically.
  # (Except if the supplied path is the same as the last scanned path,
  # and rescan is false.)
  getMappingsForRange: (start, end, path = null, rescan = false) ->
    unless (start? and end?) then throw new Error "start and end is required!"    
#    console.log "Collecting matches for [" + start + ":" + end + "]"    
    if path?
      @scan(path, rescan) 
    else
      if not @scannedPath?
        throw new Error "Can not run getMappingsFor() without existing mappings. Either supply a path to scan, or call scan() beforehand!"

    # Collect the matching mappings     
    matches = []
    for p, mapping of @mappings when mapping.atomic and @regions_overlap mapping.start, mapping.end, start, end
      do (mapping) =>
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
    result

  # ===== Private methods (never call from outside the module) =======

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
      node: node
      content: cont
      length: cont.length
    
    if node.hasChildNodes
      children = node.childNodes
      i = 0
      while i < children.length
        @collectPathsForNode(children[i], results)
        i++
    results

  getBody: -> (@rootWin.document.getElementsByTagName "body")[0]

  regions_overlap: (start1, end1, start2, end2) -> start1 < end2 and start2 < end1

#  lookUpNode: (path) ->
#    doc = @rootNode.ownerDocument ? @rootNode
#    results = doc.evaluate path, @rootNode, null, 0, null
#    node = results.iterateNext()

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
    sourceText = match.element.pathInfo.node.data.replace /\n/g, " "
    # the HTML source of the text inside a text element.

    displayText = match.element.pathInfo.content
    # what gets displayed, when the node is processed by the browser.

    displayStart = if match.start? then match.start else 0
    displayEnd = if match.end? then match.end else displayText.length
    # The selected range in displayText.

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

