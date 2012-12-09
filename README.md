# inner-peace
## Experiment about searching for text in the DOM, transcending element boundaries

## What is this

This is an experiment about how to locate text patterns in a DOM, when the match might span
multiple nodes, and we don't know where to look exactly.

The code traverses the (configured part of) the dom, and collects info about which string
slice is where. Then it searches for the pattern in the innerText of 
he (configured part of the) DOM using [google-diff-match-patch](http://code.google.com/p/google-diff-match-patch/)
(see app/lib/fancymatcher/README.txt for more info about this part.)

When a match is found, it maps in back to DOM elements, using the collected information,
and it returns info about where to text. (XPath expressions and string indices.)

Optionally, it can also highlight the match in the DOM.

All the DOM analyzing logic is in one CoffeeScript file ( app/lib/domsearcher/domsearcher.coffee )

## How to run

1. run scripts/web-server.js
2. Go to http://localhost:8000/
3. Click the buttons, and see what happens.

Or see the [live demo](http://s3.amazonaws.com/inner-peace-demo/index.html).

## Unsolved problems:

- Currently, FF is not supported. (Chrome[ium] is.)
   
  That is because FF does not support innerText.
  Will need to look into other possibilities.

- Pattern length

   Unfortunately, there is a limitation about the max length of pattern.
   The exact value varies by browser and platform, but it's typically
   32 or 64. Which means you can't search for patterns longer that that.
   (The getMaxPatternLength method returns the current limit.)

   This limitation comes from the implementation of the 
   [Bitap matching algorithm](http://neil.fraser.name/software/diff_match_patch/bitap.ps);
   will need to look into this later.
   See thread [here](https://groups.google.com/forum/?fromgroups=#!topic/diff-match-patch/VgAdlYBCHzU).

- Hidden nodes
 
   When the "display" property of a node is set to "none", it's not displayd, so it's content
   does not get into it's parent's innerText.

   However, there is no easy way to detect this when one is only looking at the DOM.
   (Like we do.)

   So, currently we are trying to detect whether a node (and it's children) is hidden by
   searching for it's innerText in the innerText of the parent.
   (If there is no match, it means that this is probably hidden.)

   However, this approach can yield "false negatives", if a node is indeed hidden, but the content
   is the same like that of an other, non-hidden node.

   This would not break the results, but would add false parts to the selection.

## Caveats:

- Whitespaces

   When the browser created the "innerText" value of a sub-tree, various complicated things happen to whitespaces found in the child nodes.

   Some get lost, some get compacted, and some get added.

   I did not really look it this, so now I just strip all whitespaces, and look for matches to determine how the
   parts overlap. This might cause some inaccuracy with the white-spaces an the ends of the selection

   Update:
 
   Now I take care of this by re-checking the content of the element (comparing it to the stored value)
   when doing the highlighting based on the search results. With this, the results are exact.

- Length of match

   It's possible to specify a search term the is longer/shorter than the original text, and it will still match.
   (That's the results of the fancy matcher algorythm.)

   However, we don't get back the length of the text it was matched to, only the starting position.
   This means that we are only guessing the length of the match is the same as the length of the search term.

   Again, this might cause some inaccuracy at the end of the selection.

   Update:

   now I do a two-phase search (look from the other end, too), so I have the proper end position.