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

