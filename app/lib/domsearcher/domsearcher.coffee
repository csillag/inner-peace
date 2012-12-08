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
  getAllPaths: -> @collectPathsForNode @pathStartNode

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
    results.push @getPathTo node
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
    node

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
#    console.log "Doing " + parentPath     
    innerText = @getNodeInnerText node

    if not innerText? or innerText is "" then return index

    if parentText?
      startIndex = parentText.indexOf innerText, index
    else
      startIndex = index

    if startIndex is -1 then return index
    endIndex = startIndex + innerText.length
    atomic = not node.hasChildNodes()
    mapping =
      "path": parentPath
      "innerText": innerText
      "start": parentIndex + startIndex
      "end": parentIndex + endIndex
      "atomic" : atomic
    results.push mapping

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

