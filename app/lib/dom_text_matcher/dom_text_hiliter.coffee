class window.DomTextHiliter

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
#    (sel.addRange results.matches[index].realRange) for index in indices when 0 <= index < len
    for index in indices when 0 <= index < len
      do (index) =>
        match = results.matches[index]
        sel.addRange match.realRrange

  highlightSearchResults: (sr, hiliteTemplate = null, indices = null) ->
    task = sections: sr.matches
    @highlight task, hiliteTemplate, indices
    task

  # Parameters:
  #   "hiliteTemplate" is a DOM node to use for wrapper for higlighting.
  #     (strong, b, i, emph, span with a class, etc can all work.)
  #     should be an actual DOM node, created by document.createElement()
  # 
  #   "indices" is an (optional) array of match numbers to select.
  #   It can be a single number, or a list, or ommitted to select all.
  highlight: (task, hiliteTemplate = null, indices = null) ->
    hiliteTemplate ?= @standardHilite

    len = task.sections.length
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
          console.log "Warning: section #" + index + " does not exist! (Allowed: [" + index + " - " + (len-1) + "])"
        else
#          console.log "Highlighting section #" + index
          for mapping in task.sections[index].mappings
            do (mapping) =>
              path = mapping.element.path
              hilitePaths[path] ?= []
              hilitePaths[path].push mapping

    # Now do the highlighting
    for path, mappings of hilitePaths
      do (path, mappings) =>
        node = mappings[0].element.node
        unless node?
          console.log "Node missing. Looking it up..."
          node = @domMapper.lookUpNode mappings[0].element.path
        charRanges = @uniteCharRanges ({full: mapping.full, start: mapping.startCorrected, end: mapping.endCorrected, yields: mapping.yields } for mapping in mappings)
#        console.log "charRanges: "
#        console.log charRanges
        clone = node.cloneNode()
        mapping.element.node = clone for mapping in mappings

        isImg = node.nodeType is Node.ELEMENT_NODE and node.tagName.toLowerCase() is "img"

        if isImg
          full = true
        else
          len = node.data.length
          full = charRanges.length is 1 and
              (charRanges[0].full or
              (charRanges[0].start is 0 and charRanges[0].end is len))
        
        if full
          # easy to do, can highlight full element
          hl = @hilite node, hiliteTemplate
          toInsert.push
            node: clone
            before: hl
          toRemove.push hl
 #         console.log "Done full cut."
        else
            # Unfortunately, we need to mess around the insides of this element
            index = 0
            firstRegion = true
            nextPart = node
            for charRange in charRanges
              do (charRange) =>
                if charRange.start is 0
                  # This is the first charRange, and it starts at the start of the node
                  nextPart = nextPart.splitText charRange.end
                  firstPart = nextPart.previousSibling
#                  if firstPart.data isnt charRange.yields
#                    console.log "Start cut. Wanted: '" + charRange.yields + "'; got: '" + firstPart.data + "'."
#                  else
#                    console.log "Done start cut."
                  hl = @hilite firstPart, hiliteTemplate
                  toInsert.push
                    node: clone
                    before: hl
                  toRemove.push hl
                  index = charRange.end
                else if charRange.end is len
                  # this is the last charRange, and it ends at the end of the node
                  lastPart = nextPart.splitText charRange.start - index
                  nextPart = null
                  remainingPart = lastPart.previousSibling
#                  if lastPart.data isnt charRange.yields
#                    console.log "End cut. Wanted: '" + charRange.yields + "'; got: '" + lastPart.data + "'."
#                  else
#                    console.log "Done end cut."
                  hl = @hilite lastPart, hiliteTemplate
                  if firstRegion then toInsert.push
                    node: clone
                    before: remainingPart
                  toRemove.push remainingPart
                  toRemove.push hl
                else
                  # this charRange is is at the middle of the node
#                  console.log "Gonna split @ " + charRange.start + "-" + index + " = " + (charRange.start - index) + " (len is: " + nextPart.data.length + ")"
                  middlePart = nextPart.splitText charRange.start - index
                  beforePart = middlePart.previousSibling
#                  console.log "Gonna split @ " + charRange.end + "-" + charRange.start + "=" + (charRange.end - charRange.start) + " (len is: " + middlePart.data.length + ")"
                  nextPart = middlePart.splitText charRange.end - charRange.start
#                  if middlePart.data isnt charRange.yields
#                    console.log "Middle cut. Wanted: '" + charRange.yields + "'; got: '" + middlePart.data + "'."
#                  else
#                    console.log "Done middle cut."
                  hl = @hilite middlePart, hiliteTemplate
                  if firstRegion then toInsert.push
                    node: clone
                    before: beforePart
                  toRemove.push beforePart
                  toRemove.push hl
                  index = charRange.end
                firstRange = false
            if nextPart? then toRemove.push nextPart                

    task.undo =
      insert: toInsert
      remove: toRemove

    @allActive.undo.insert.push toInsert...
    @allActive.undo.remove.push toRemove...

    null

  # Call this to undo a highlighting task
  #
  # It's your responsibility to only call this if a highlight is at place.
  # (Altought calling it more than once will do no harm.)
  # Pass in the task that was used with the highlighting.
  undo: (task) ->
    unless task?.undo?
#      console.log "Nothing to undo"
      return
#    console.log "Undo hilite: " + task.undo.insert.length + " insertions, " + task.undo.remove.length + " deletions."
    insert.before.parentNode.insertBefore insert.node, insert.before for insert in task.undo.insert
    task.undo.insert = []
    remove.parentNode.removeChild remove for remove in task.undo.remove
    task.undo.remove = []

  clean: ->
    console.log "Hilite cleanup"
    @undo @allActive
    console.log "Done"
  
        
  # ===== Private methods (never call from outside the module) =======

  constructor: (domTextMapper) ->
    @domMapper = domTextMapper    
    hl = document.createElement "span"
    hl.setAttribute "style", "background-color: yellow; color: black; border-radius: 3px; box-shadow: 0 0 2px black;"
    @standardHilite = hl
    @allActive = undo: 
      insert: []
      remove: []

  hilite: (node, template) ->
    parent = node.parentNode
    unless parent? then throw new Error "Hilited node has no parent!"
    hl = template.cloneNode()
    hl.appendChild node.cloneNode()
    node.parentNode.insertBefore hl, node
    node.parentNode.removeChild node        
    hl    

  compareCharRanges: (a,b) ->
    if a.start < b.start
      -1
    else if a.start > b.start
      1
    else if a.end < b.end
      -1
    else if a.end > b.end
      1
    else
      0

  uniteCharRanges: (charRanges) ->
    united = []
    delete lastRange
#    console.log "Uniting charRanges: "
#    console.log charRanges
    for charRange in charRanges.sort @compareCharRanges
      if charRange.full then full = charRange          
#      console.log "Doing range: "
#      console.log range
      if lastRange? and lastRange.end >= charRange.start
#        console.log "Can unite..."
        # there was a previous character range, and we can continue it
        if charRange.end > lastRange.end
#          console.log "Old yields: '" + lastRange.yields + "'."
#          console.log "New yields: '" + range.yields + "'."
          addLen = charRange.end - lastRange.end
          addPart = charRange.yields.substr charRange.yields.length - addLen, addLen
          lastRange.yields = lastRange.yields + addPart
          lastRange.end = charRange.end
#          console.log "Should have appended the yield value, too: '" + lastRange.yields + "'."
      else
#        console.log "New unit. (Last ended @ " + lastRange?.end + "; new start @ " + range.start + ")"
        # no previous range, or it's too far off
        united.push lastRange =
          start: charRange.start
          end: charRange.end
          yields: charRange.yields
    if full? then united = [ full ]
 #   console.log "As united:"
#    console.log united
    united

