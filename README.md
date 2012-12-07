# inner-peace
## Experiment about searching for text in the DOM, transcending element boundaries

1. run scripts/web-server.js
2. Go to http://localhost:8000/
3. Click the buttons, and see what happens.

Unsolved problems:

1. Hidden nodes.
 
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

2. Whitespaces

   When the browser created the "innerText" value of a sub-tree, various complicated things happen to whitespaces found in the child nodes.

   Some get lost, some get compacted, and some get added.

   I did not really look it this, so now I just strip all whitespaces, and look for matches to determine how the
   parts overlap. This might cause some inaccuracy with the white-spaces an the ends of the selection

3. Length of match

   It's possible to specify a search term the is longer/shorter than the original text, and it will still match.
   (That's the results of the fancy matcher algorythm.)

   However, we don't get back the length of the text it was matched to, only the starting position.
   This means that we are only guessing the length of the match is the same as the length of the search term.

   Again, this might cause some inaccuracy at the end of the selection.
