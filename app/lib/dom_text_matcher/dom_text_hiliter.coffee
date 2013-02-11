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
#    (sel.addRange results.matches[index].range) for index in indices when 0 <= index < len
    for index in indices when 0 <= index < len
      do (index) =>
        match = results.matches[index]
        sel.addRange match.range

  highlightSearchResults: (sr, hiliteTemplate = null, indices = null) ->
    task = ranges: sr.matches
    @highlight(task, hiliteTemplate, indices)
    task

  # Parameters:
  #   "hiliteTemplate" is a DOM node to use for wrapper for higlighting.
  #     (strong, b, i, emph, span with a class, etc can all work.)
  #     should be an actual DOM node, created by document.createElement()
  # 
  #   "indices" is an (optional) array of match numbers to select.
  #   It can be a single number, or a list, or ommitted to select all.
  highlight: (task, hiliteTemplate = null, indices = null) ->

#    console.log "Got hiliting task: "
#    console.log task

    hiliteTemplate ?= @standardHilite

    len = task.ranges.length
#    console.log "Got " + len + " ranges."
    if indices?
      if typeof indices is 'number' then indices = [indices]
    else
#      console.log "Got no indices to start with"
      if len
#        console.log "Creating full indices"
        indices = [0 ... len]
      else
#        console.log "Nothing to do"
        return
#    console.log "Indices are: "
#    console.log indices

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
          for match in task.ranges[index].nodes
            do (match) =>
              path = match.element.pathInfo.path
              hilitePaths[path] ?= []
              hilitePaths[path].push match
 
    # Now do the highlighting
    for path, matches of hilitePaths
      do (path, matches) =>
#        console.log "Doing new node."
        node = matches[0].element.pathInfo.node
        unless node?
          console.log "Node missing. Looking it up..."
          node = @domMapper.lookUpNode matches[0].element.pathInfo.path
#          console.log "Found. "
#          console.log node
#        else
#          console.log "Node is:"
#          console.log node
#        console.log "Matches: "
#        console.log matches
        # Calculate a normalized set of ranges 
        ranges = @uniteRanges ({start: match.startCorrected, end: match.endCorrected, yields: match.yields } for match in matches)
#        console.log "Ranges: "
#        console.log ranges
        clone = node.cloneNode()
        match.element.pathInfo.node = clone for match in matches

        len = node.data.length
        full = ranges.length is 1 and ranges[0].start is 0 and ranges[0].end is len
        if full
          # easy to do, can highlight full element
          hl = @hilite node, hiliteTemplate
          toInsert.push
            node: clone
            before: hl
          toRemove.push hl
#          console.log "Done full cut."
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
#                  if firstPart.data isnt range.yields
#                    console.log "Start cut. Wanted: '" + range.yields + "'; got: '" + firstPart.data + "'."
#                  else
#                    console.log "Done start cut."
                  hl = @hilite firstPart, hiliteTemplate
                  toInsert.push
                    node: clone
                    before: hl
                  toRemove.push hl
                  index = range.end
                else if range.end is len
                  # this is the last range, and it ends at the end of the node
                  lastPart = nextPart.splitText range.start - index
                  nextPart = null
                  remainingPart = lastPart.previousSibling
 #                 if lastPart.data isnt range.yields
#                    console.log "End cut. Wanted: '" + range.yields + "'; got: '" + lastPart.data + "'."
#                  else
#                    console.log "Done end cut."
                  hl = @hilite lastPart, hiliteTemplate
                  if firstRegion then toInsert.push
                    node: clone
                    before: remainingPart
                  toRemove.push remainingPart
                  toRemove.push hl
                else
                  # this range is is at the middle of the node
#                  console.log "Gonna split @ " + range.start + "-" + index + " = " + (range.start - index) + " (len is: " + nextPart.data.length + ")"
                  middlePart = nextPart.splitText range.start - index
                  beforePart = middlePart.previousSibling
#                  console.log "Gonna split @ " + range.end + "-" + range.start + "=" + (range.end - range.start) + " (len is: " + middlePart.data.length + ")"
                  nextPart = middlePart.splitText range.end - range.start
#                  if middlePart.data isnt range.yields
#                    console.log "Middle cut. Wanted: '" + range.yields + "'; got: '" + middlePart.data + "'."
#                  else
#                    console.log "Done middle cut."
                  hl = @hilite middlePart, hiliteTemplate
                  if firstRegion then toInsert.push
                    node: clone
                    before: beforePart
                  toRemove.push beforePart
                  toRemove.push hl
                  index = range.end
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
    unless parent?
      console.log "Warning: hilited node has no parent!"
      console.log node
      return
    hl = template.cloneNode()
    hl.appendChild node.cloneNode()
    node.parentNode.insertBefore hl, node
    node.parentNode.removeChild node        
    hl    

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
    delete lastRange
#    console.log "Uniting ranges: "
#    console.log ranges
    for range in ranges.sort @compareRanges
#        console.log "Doing range: "
#        console.log range
        if lastRange? and lastRange.end >= range.start
#          console.log "Can unite..."
          # there was a previous range, and we can continue it
          if range.end > lastRange.end
#            console.log "Old yields: '" + lastRange.yields + "'."
#            console.log "New yields: '" + range.yields + "'."
            addLen = range.end - lastRange.end
            addPart = range.yields.substr range.yields.length - addLen, addLen
            lastRange.yields = lastRange.yields + addPart
            lastRange.end = range.end
#            console.log "Should have appended the yield value, too: '" + lastRange.yields + "'."
        else
#          console.log "New unit. (Last ended @ " + lastRange?.end + "; new start @ " + range.start + ")"
          # no previous range, or it's too far off
          united.push lastRange =
            start: range.start
            end: range.end
            yields: range.yields
#    console.log "As united:"
#    console.log united
    united

