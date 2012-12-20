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
    iframe = document.getElementById iframeId
    @rootWin = iframe.contentWindow
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
  # An array is returned, with each entry containing a "path" and a "length" field.
  # The value of the "path" field is the valid path value, "length" contains information
  # about the length of content belonging to the given path.
  getAllPaths: -> @collectPathsForNode @pathStartNode

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
    if not path? then path = @getAllPaths()[0]
    if path is @scannedPath and not rescan then return
    node = @lookUpNode path
    @mappings = []
    @collectStrings node, path, null, 0, 0
    @scannedPath = path
    @corpus = @mappings[0].content
    null

  # Get the matching DOM elements for a given text range
  # 
  # If the "path" argument is supplied, scan is called automatically.
  # (Except if the supplied path is the same as the last scanned path,
  # and rescan is false.)
  getMappingsFor: (start, end, path = null, rescan = false) ->
    if path?
      @scan(path, rescan) 
    else
      if not @scannedPath?
        throw new Error "Can not run getMappingsFor() without existing mappings. Either supply a path to scan, or call scan() beforehand!"

    # Collect the matching mappings     
    matches = []
    for mapping in @mappings when mapping.atomic and @regions_overlap mapping.start, mapping.end, start, end
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
            match.wanted = mapping.content.substr 0, match.end                
          else if mapping.end <= end
            match.start = start - mapping.start
            match.wanted = mapping.content.substr match.start        
          else
            match.start = start - mapping.start
            match.end = end - mapping.start
            match.wanted = mapping.content.substr match.start, match.end - match.start
        @computeSourcePositions match
        match.yields = mapping.node.data.substr match.startCorrected, match.endCorrected - match.startCorrected
        matches.push match

    # Create a DOM range object
    r = @rootWin.document.createRange()
    startMatch = matches[0]
    startNode = startMatch.element.node
    startInfo = startMatch.element.path
    if startMatch.full
      r.setStartBefore startNode
    else
      r.setStart startNode, startMatch.startCorrected
      startInfo += ":" + startMatch.startCorrected

    endMatch = matches[matches.length - 1]
    endNode = endMatch.element.node
    endInfo = endMatch.element.path
    if endMatch.full
      r.setEndAfter endNode
    else
      r.setEnd endNode, endMatch.endCorrected
      endInfo += ":" + endMatch.endCorrected

    result = {
      nodes: matches
      range: r
      rangeInfo:
        start: startInfo
        end: endInfo
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

  collectPathsForNode: (node, results = []) ->
    if @careAboutNodeType and node.nodeType in @ignoredNodeTypes and results.length > 0 then return

    len = (@getNodeContent node).length
    if len then results.push
      path: @getPathTo node
      length: len
    
    if node.hasChildNodes
      children = node.childNodes
      i = 0
      while i < children.length
        @collectPathsForNode(children[i], results)
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
    @oldRanges = (sel.getRangeAt i) for i in [0 ... sel.rangeCount]
    @oldRanges ?= []

  # restore selection
  restoreSelection: ->
    sel = @rootWin.getSelection()
    sel.removeAllRanges()
    sel.addRange range for range in @oldRanges

  # Read the "text content" of a sub-tree of the DOM by creating a selection from it
  getNodeSelectionText: (node, shouldRestoreSelection = true) ->
    sel = @rootWin.getSelection()                

    if shouldRestoreSelection then @saveSelection()

    # clear the selection
    sel.removeAllRanges()

    # create our range, and select it
    range = @rootWin.document.createRange()
    range.setStartBefore node
    range.setEndAfter node
    sel.addRange range

    # read (and convert) the content of the selection
    text = sel.toString().trim().replace(/\n/g, " ").replace /[ ][ ]+/g, " "

    if shouldRestoreSelection then @restoreSelection()
    text


  # Convert "display" text indices to "source" text indices.
  computeSourcePositions: (match) ->
    sourceText = match.element.node.data.replace /\n/g, " "
    # the HTML source of the text inside a text element.

    displayText = match.element.content
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

  getNodeContent: (node) -> @getNodeSelectionText node

  collectStrings: (node, parentPath, parentContent = null, parentIndex = 0, index = 0) ->
#    console.log "Scanning path " + parentPath    
    content = @getNodeContent node

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
    @mappings.push
      "path": parentPath
      "node": node
      "content": content
      "start": parentIndex + startIndex
      "end": parentIndex + endIndex
      "atomic" : atomic

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

