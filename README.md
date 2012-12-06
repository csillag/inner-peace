# angular-seed-coffeescript
## The seed for AngularJS apps, in coffeescript

This project is a straight [coffeescript](http://coffeescript.org/) port of the [angular-seed](https://github.com/angular/angular-seed) project.

I (csillag) just took [this project](https://github.com/slavus/angular-seed-coffeescript), and merged the newest changes from [upstream](https://github.com/angular/angular-seed) - which means roughly bringing the project up from angular 1.0.1 to 1.0.3. (Except the testing-related changes, which I ignored for now.)

## Status

Ready for use.

## Noted differences from angular-seed
* The use of coffeescript requires that Angular be [bootstrapped manually](http://docs.angularjs.org/guide/bootstrap).
	* `ng-app` has been removed from `html` element of `index.html`
	* `angular.bootstrap` called in  `app.coffee`
* In `angular-seed` controllers are defined as global functions.  Since coffeescript runs in an anonymous function, the controllers need to be attached directly to the `window` object

## TODOs

* Bring back index-async.html
* Port tests to coffeescript (currently still js)
* Merge all test-related changes from angular-seed introduced since Angular version 1.0.1
