class window.DomSearcher
  constructor: (fancyMatcher) -> @fancyMatcher = fancyMatcher

  getProperNodeName: (element) ->
    nodeName = element.nodeName
    switch nodeName
      when "#text" then return "text()"
      when "#comment" then return "comment()"
      when "#cdata-section" then return "cdata-section()"
      else return nodeName
                
  getPathTo: (el, rootElement = document) ->
    xpath = '';
    while el != rootElement
      pos = 0
      tempitem2 = el
      while tempitem2
        if tempitem2.nodeName is el.nodeName
          pos++
        tempitem2 = tempitem2.previousSibling

      xpath = (@getProperNodeName el) + (if pos>1 then "[" + pos + ']' else "") + '/' + xpath
      el = el.parentNode
    xpath = (if rootElement.ownerDocument? then './' else '/') + xpath
    xpath = xpath.replace /\/$/, ''
    xpath

  collectPathsForElement: (startElement, rootElement, results = []) ->
    if startElement.nodeType in @ignoredNodeTypes and results.length > 0 then return
    results.push @getPathTo startElement, rootElement
    if startElement.hasChildNodes
      children = startElement.childNodes
      i = 0
      while i < children.length
        @collectPathsForElement(children[i], rootElement, results)
        i++
    results

  getBody: -> (document.getElementsByTagName "body")[0]
        
  collectSubPaths: (startId = null, rootId = null) ->
    startElement = if startId? then document.getElementById rootId else @getBody()
    rootElement = if rootId? then document.getElementById rootId else document
    @collectPathsForElement startElement, rootElement

  collectPaths: -> @collectSubPaths null, null

  lookUpNode: (path, rootElement = document) ->
    root = rootElement ? document
    doc = root.ownerDocument ? root
    results = doc.evaluate path, root, null, 0, null
    node = results.iterateNext()
    node

  ignoredNodeTypes: [
    Node.ATTRIBUTE_NODE,
    Node.DOCUMENT_TYPE_NODE,
    Node.COMMENT_NODE,
    Node.PROCESSING_INSTRUCTION_NODE
  ]

#      when Node.ENTITY_REFERENCE_NODE, Node.ENTITY_NODE, Node.DOCUMENT_FRAGMENT_NODE, Node.NOTATION_NODE
#        console.log "Encountered node type " + node.nodeType + ". Not sure how to handle this."
#        return null

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

  getPathInnerText: (path, rootId = null) ->
    rootElement = if rootId? then document.getElementById rootId else document        
    @getNodeInnerText @lookUpNode path, rootElement

  getBodyInnerText: ->
    @getNodeInnerText @getBody()

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

  regions_overlap: (start1, end1, start2, end2) ->
    start1 < end2 and start2 < end1
 
  collectElements: (mappings, startPos, endPos) ->
    matches = []
    for mapping in mappings when mapping.atomic and @regions_overlap mapping.start, mapping.end, startPos, endPos
      do (mapping) ->
        match =
          path: mapping.path
          text: mapping.innerText
        if startPos <= mapping.start and mapping.end <= endPos
#           console.log mapping.path + " - full"
          match["full"] = true
        else if startPos <= mapping.start
          match["end"] = endPos - mapping.start
#           console.log mapping.path + " - [:" + (endPos - mapping.start) + "]"
        else if mapping.end <= endPos
          match["start"] = startPos - mapping.start
#           console.log mapping.path + " - [" + (startPos - mapping.start) + ":]"        
        else
          match["start"] = startPos - mapping.start
          match["end"] = endPos - mapping.start
   #           console.log mapping.path + " - [" + (startPos - mapping.start) + ":" + (endPos - mapping.start) + "]"

        matches.push match
        
    matches    

  collectContents: (path, rootId) ->
    rootElement = document.getElementById rootId
    node = @lookUpNode path, rootElement

    results = []
    @collectStrings node, path, null, 0, 0, results
    results

  search: (corpus, searchTerm, searchPos) ->
    @fancyMatcher.search corpus, searchTerm, searchPos