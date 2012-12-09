class window.DomSearcher
  constructor: (fancyMatcher) -> @fancyMatcher = fancyMatcher

  # ===== Public methods =======

  # To use the module, first you need to configure the root node to use for all operations.
  # This can be either the full document, or a specific sub-set of it.

  # Consider the whole DOM tree
  setRealRoot: ->
    @rootNode = document
    @pathStartNode = @getBody() 
        
  # Consider the sub-tree beginning with this node
  setRootNode: (rootNode) -> @pathStartNode = @rootNode = rootNode    

  # Consider the sub-tree beginning with the node whose ID was given
  setRootId: (rootId) -> @setRootNode document.getElementById rootId

  # After you have configured the root node to use, you can query the available paths
  # 
  # An array is returned, with each entry containing a "path" and a "length" field.
  # The value of the "path" field is the valid path value, "length" contains information
  # about the length of innerText belonging to the given path.
  getAllPaths: -> @collectPathsForNode @pathStartNode

  # Use this to get the max allowed pattern length.
  # Trying to use a longer pattern will give an error.
  getMaxPatternLength: -> @fancyMatcher.getMaxPatternLength()
        
  # Use this to search for text
  #
  # Parameters:
  #  searchPath: the sub-tree inside the DOM you want to search.
  #    Must be an XPath expression, relative to the configured root node.
  #    You can check for valid input values using the getAllPaths method above.
  #  searchPattern: what to search for
  #  searchPos: where do we expect to find it
  #  matchDistance and matchThreshold: fine-tuning parameters for the text matching
  #  library. See http://code.google.com/p/google-diff-match-patch/wiki/API for details.
  #
  # The returned object will have "start", "end", "found" and "nodes" fields.
  # start and end specify where the pattern was found; "found" is the matching slice.
  # Nodes is the list of matching nodes, with details about the matches.
  # 
  # If no match is found, null is returned.  # 
  search: (searchPath, searchPattern, searchPos, matchDistance = 1000, matchThreshold = 0.5) ->

    maxLength = @getMaxPatternLength()
    wantedLength = searchPattern.length
    if wantedLength > maxLength
      alert "Pattern is longer than allowed by the search library. (Max is " + maxLength + "; requested is " + wantedLength + ".)"
      return
        
    @fancyMatcher.setMatchDistance matchDistance
    @fancyMatcher.setMatchThreshold matchThreshold
    @corpus = @getNodeInnerText @lookUpNode searchPath
    sr = @fancyMatcher.search @corpus, searchPattern, searchPos
    if sr?
      mappings = @collectMappings searchPath                
      matches = []
      for mapping in mappings when mapping.atomic and @regions_overlap mapping.start, mapping.end, sr.start, sr.end
        do (mapping) ->
          match =
            path: mapping.path
            text: mapping.innerText
          if sr.start <= mapping.start and mapping.end <= sr.end
            match["full"] = true
          else if sr.start <= mapping.start
            match["end"] = sr.end - mapping.start
          else if mapping.end <= sr.end
            match["start"] = sr.start - mapping.start
          else
            match["start"] = sr.start - mapping.start
            match["end"] = sr.end - mapping.start
          matches.push match
      sr.nodes = matches
    sr

  # Call this to highlight search results
  highlight: (searchResult) ->
    match.node = @lookUpNode match.path for match in searchResult.nodes

    toInsert = []
    toRemove = []
    
    for match in searchResult.nodes
      do (match) =>
        clone = match.node.cloneNode()
        if match.full # easy to do, can highlight full element
          hl = @hilite match.node
          toInsert.push
            node: clone
            before: hl
          toRemove.push hl
        else
          window.wtfnode = match.node        
          offset = match.node.data.indexOf match.text
          if not match.end? # from the start, to a given position
            secondPart = match.node.splitText(match.start + offset)
            firstPart = secondPart.previousSibling
            hl = @hilite secondPart
            toInsert.push
              node: clone
              before: firstPart
            toRemove.push firstPart
            toRemove.push hl
          else if not match.start? # from a position till the end
            secondPart = match.node.splitText(match.end + offset)
            firstPart = secondPart.previousSibling
            hl = @hilite firstPart
            toInsert.push
              node: clone
              before: hl
            toRemove.push hl
            toRemove.push secondPart        
          else
            secondPart = match.node.splitText(match.start + offset)
            firstPart = secondPart.previousSibling
            thirdPart = secondPart.splitText(match.end - match.start)
            hl = @hilite secondPart
            toInsert.push
              node: clone
              before: firstPart
            toRemove.push firstPart
            toRemove.push hl
            toRemove.push thirdPart

    searchResult.undoHilite =
      insert: toInsert
      remove: toRemove

  # Call this to undo highlighting search results
  #
  # It's your responsibility to only call this if a highlight is at place.
  # Pass in the searchResult that was used with the highlighting.
  undoHighlight: (searchResult) ->
    insert.before.parentNode.insertBefore insert.node, insert.before for insert in searchResult.undoHilite.insert
    remove.parentNode.removeChild remove for remove in searchResult.undoHilite.remove
    searchResult.undoHilite = null
  
        
  # ===== Private methods (never call from outside the module) =======

  hilite: (node) ->
    hl = document.createElement "span"
    hl.setAttribute "class", "hl"
    hl.appendChild node.cloneNode()
    node.parentNode.insertBefore hl, node
    node.parentNode.removeChild node        
    hl    

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

  ignoredNodeTypes: [
    Node.ATTRIBUTE_NODE,
    Node.DOCUMENT_TYPE_NODE,
    Node.COMMENT_NODE,
    Node.PROCESSING_INSTRUCTION_NODE
  ]

#      when Node.ENTITY_REFERENCE_NODE, Node.ENTITY_NODE, Node.DOCUMENT_FRAGMENT_NODE, Node.NOTATION_NODE
#        console.log "Encountered node type " + node.nodeType + ". Not sure how to handle this."
#        return null

  collectPathsForNode: (node, results = []) ->
    if node.nodeType in @ignoredNodeTypes and results.length > 0 then return
    results.push
      path: @getPathTo node
      length: (@getNodeInnerText node).length
    
    if node.hasChildNodes
      children = node.childNodes
      i = 0
      while i < children.length
        @collectPathsForNode(children[i], results)
        i++
    results

  getBody: -> (document.getElementsByTagName "body")[0]

  regions_overlap: (start1, end1, start2, end2) -> start1 < end2 and start2 < end1

  lookUpNode: (path) ->
    doc = @rootNode.ownerDocument ? @rootNode
    results = doc.evaluate path, @rootNode, null, 0, null
    node = results.iterateNext()

  getNodeInnerText: (node) ->
    switch node.nodeType
      when Node.ATTRIBUTE_NODE, Node.DOCUMENT_TYPE_NODE, Node.COMMENT_NODE, Node.PROCESSING_INSTRUCTION_NODE
        return ""
      when Node.DOCUMENT_NODE then return "Not yet implemented"
      when Node.TEXT_NODE then return node.data.trim()
      when Node.CDATA_SECTION_NODE then return node.data
      when Node.ELEMENT_NODE then return node.innerText
      when Node.ENTITY_REFERENCE_NODE, Node.ENTITY_NODE, Node.DOCUMENT_FRAGMENT_NODE, Node.NOTATION_NODE
        console.log "Encountered node type " + node.nodeType + ". Not sure how to handle this."
        return ""

  collectStrings: (node, parentPath, parentText = null, parentIndex = 0, index = 0, results = []) ->
    innerText = @getNodeInnerText node

    if not innerText? or innerText is "" then return index

    if parentText?
      startIndex = parentText.indexOf innerText, index
    else
      startIndex = index

    if startIndex is -1 then return index
    endIndex = startIndex + innerText.length
    atomic = not node.hasChildNodes()
    results.push
      "path": parentPath
      "innerText": innerText
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
        pos=@collectStrings child, childPath, innerText, parentIndex + startIndex, pos, results
        i++

    endIndex

  collectMappings: (path) ->
    node = @lookUpNode path
    results = []
    @collectStrings node, path, null, 0, 0, results
    results

  collectMatchingNodes: (sr) ->

