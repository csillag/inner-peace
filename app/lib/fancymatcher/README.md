# fancy-matcher
## Sophisticated plain text searching

## What is it

This module is a simple wrapper for [google-diff-match-patch](http://code.google.com/p/google-diff-match-patch/)

It only exposes the text search functions of the JS library; the diff and patch functions are only available on the original library.

The only new feature added locally is the two-phase searching:
 - First we search normally, to find the match starting point
 - Then we search for the reversed pattern in the reversed text, to find the match ending point

This way, we can return a range for the match, not just the starting position.
This is required for determining the length of selection in cases then the match is not exact.

## How to use it

To use it, you must include the original JS library, too.
Then include the module, and you are set.

If you want to use it with Angular, you can register it as an angular service, like this:

    angular.module 'whatever', [], ($provide) ->
      $provide.factory "fancyMatcher", -> getInstance: -> new FancyMatcher

And then you can use the usual DI to get the service.

(Use getInstance on it to get an actual instance; it can not be a singletone,
since it's stateful.)
