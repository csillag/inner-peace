# dmp
## diff-match-patch wrapper module for Angular.js

## What is it

This Angular.js module is a simple wrapper for [google-diff-match-patch](http://code.google.com/p/google-diff-match-patch/). written in CoffeeScript.

It only exposes the text search functions of the JS library; the diff and patch functions are only available on the original library.

The only new feature added locally is the two-phase searching:
 - First we search normally, to find the match starting point
 - Then we search for the reversed pattern in the reversed text, to find the match ending point

This way, we can return a range for the match, not just the starting position.
This is required for determining the length of selection in cases then the match is not exact.

## How to use it

To use it, you must include the original JS library, too.
Then include the module, and you are set.

The name of the angular moduel is 'dmp', and the provided service is $dmpMatcher.

(Use getInstance on it to get an actual instance; it can not be a singletone,
since it's stateful.)

## Problems

Unfortunately, there is a limitation about the max length of pattern.
The exact value varies by browser and platform, but it's typically
32 or 64. Which means you can't search for patterns longer that that.
(The getMaxPatternLength method returns the current limit.)

This limitation comes from the implementation of the 
[Bitap matching algorithm](http://neil.fraser.name/software/diff_match_patch/bitap.ps);
will need to look into this later.