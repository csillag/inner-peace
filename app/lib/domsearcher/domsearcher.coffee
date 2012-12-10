class window.DomSearcher
  constructor: (dmpMatcher) -> @dmp = dmpMatcher

  # ===== Public methods =======

  # Call this to test browser compatibility.
  # Returned structure has an "ok" field, which is boolean.
  # If true, we are good to go. If false, the "message" field describes the problem.
  testBrowserCompatibility: ->
    hasInnerText = @getBody().innerText?
    ok = @contentMode isnt "innerText" or hasInnerText
    result = 
      ok: ok
      message: if ok then "We are OK" else "Unfortunately, your browser does not support innerText. Try this with Chrome[ium]."

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
  # about the length of content belonging to the given path.
  getAllPaths: -> @collectPathsForNode @pathStartNode

  # Use this to get the max allowed pattern length.
  # Trying to use a longer pattern will give an error.
  getMaxPatternLength: -> @dmp.getMaxPatternLength()
        
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
        
    @dmp.setMatchDistance matchDistance
    @dmp.setMatchThreshold matchThreshold
    @corpus = @getNodeContent @lookUpNode searchPath
    sr = @dmp.search @corpus, searchPattern, searchPos
    if sr?
      mappings = @collectMappings searchPath                
      matches = []
      for mapping in mappings when mapping.atomic and @regions_overlap mapping.start, mapping.end, sr.start, sr.end
        do (mapping) ->
          match =
            element: mapping
          # take care of useless whitespaces at the start of the node
          offset = mapping.node.data.indexOf mapping.content
          # TODO: what about compacted whitespace mid-element?         
          full_match = sr.start <= mapping.start and mapping.end <= sr.end
          if full_match 
            match.full = true
            match.wanted = mapping.content
            match.yields = mapping.node.data
          else if offset is -1
            console.log "Problem identifying proper offset from inside this text block."
            # this is _not a full match, but we can't reliably find the position,
            # so wi will treat it as such.
            match.full = true
            match.yields = mapping.node.data            
          else
           if sr.start <= mapping.start
              match.end = sr.end - mapping.start
              match.wanted = mapping.content.substr 0, match.end                
              match.endCorrected = match.end + offset
              match.yields = mapping.node.data.substr 0, match.endCorrected
            else if mapping.end <= sr.end
              match.start = sr.start - mapping.start
              match.wanted = mapping.content.substr match.start        
              match.startCorrected = match.start + offset
              match.yields = mapping.node.data.substr match.startCorrected
            else
              match.start = sr.start - mapping.start
              match.end = sr.end - mapping.start
              match.wanted = mapping.content.substr match.start, match.end - match.start
              match.startCorrected = match.start + offset
              match.endCorrected = match.end + offset
              match.yields = mapping.node.data.substr match.startCorrected, match.end - match.start
          matches.push match
      sr.nodes = matches
    sr

  # Call this to highlight search results
  highlight: (searchResult) ->

    toInsert = []
    toRemove = []
    
    for match in searchResult.nodes
      do (match) =>
        node = match.element.node
        clone = node.cloneNode()
        match.element.node = clone
        if match.full # easy to do, can highlight full element
          hl = @hilite node
          toInsert.push
            node: clone
            before: hl
          toRemove.push hl
        else
          if not match.end? # from the start, to a given position
            secondPart = node.splitText(match.startCorrected)
            firstPart = secondPart.previousSibling
            hl = @hilite secondPart
            toInsert.push
              node: clone
              before: firstPart
            toRemove.push firstPart
            toRemove.push hl
          else if not match.start? # from a position till the end
            secondPart = node.splitText(match.endCorrected)
            firstPart = secondPart.previousSibling
            hl = @hilite firstPart
            toInsert.push
              node: clone
              before: hl
            toRemove.push hl
            toRemove.push secondPart        
          else
            secondPart = node.splitText(match.startCorrected)
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
    unless searchResult.undoHilite? then return
    insert.before.parentNode.insertBefore insert.node, insert.before for insert in searchResult.undoHilite.insert
    remove.parentNode.removeChild remove for remove in searchResult.undoHilite.remove
    searchResult.undoHilite = null
  
        
  # ===== Private methods (never call from outside the module) =======

  contentMode:
    "selection"
#    "innerText"
  careAboutNodeType: @contentMode is "innerText"

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
    if @careAboutNodeType and node.nodeType in @ignoredNodeTypes and results.length > 0 then return
    results.push
      path: @getPathTo node
      length: (@getNodeContent node).length
    
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

  # Read the "text content" of a sub-tree of the DOM by creating a selection from it
  getNodeSelectionText: (node) ->
     range = document.createRange()
     range.setStartBefore node
     range.setEndAfter node
     sel = window.getSelection()
     sel.removeAllRanges()
     sel.addRange range
     text = sel.toString()
     sel.removeAllRanges()
     text.trim()

  getNodeContent: (node) ->
    switch @contentMode
      when "innerText" then @getNodeInnerText node
      when "selection" then @getNodeSelectionText node
        
  collectStrings: (node, parentPath, parentContent = null, parentIndex = 0, index = 0, results = []) ->
#    console.log "Doing path " + parentPath    
    content = @getNodeContent node
    if not content? or content is ""
#      console.log "No content here."  
      return index
    else
#      console.log "Content is '" + content + "'"

    startIndex = if parentContent? then (parentContent.indexOf content, index) else index

    if startIndex is -1
#      console.log "Content ('" + content + "' is not found in parentConent '" + parentContent + "'."
      return index

    endIndex = startIndex + content.length
    atomic = not node.hasChildNodes()
    results.push
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
        pos=@collectStrings child, childPath, content, parentIndex + startIndex, pos, results
        i++

    endIndex

  collectMappings: (path) ->
    node = @lookUpNode path
    results = []
    @collectStrings node, path, null, 0, 0, results
    results

