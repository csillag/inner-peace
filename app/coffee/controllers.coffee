#Controllers

class SearchController
  this.$inject = ['$scope', '$timeout', '$filter', 'domSearcher']
  constructor: ($scope, $timeout, $filter, domSearcher) ->

    $scope.rootId = "rendered-dom" #this is ID of the DOM element we use for rendering the demo HTML
    $scope.sourceMode = "local"
    $scope.localSource = "This is <br /> a <i>test</i> <b>text</b>. <div>Has <div>some</div><div>divs</div>, too.</div>"
    $scope.atomicOnly = true

    $scope.$watch 'sourceMode', (newValue, oldValue) ->
      $scope.paths = []
      $scope.mappings = []

      if $scope.sourceMode == "local"
      else
        $scope.renderSource = null
        if $scope.sourceMode == "page"
          $timeout -> $scope.checkPage()
        else
        
    $scope.render = ->
      $scope.renderSource = $scope.localSource
      $scope.paths = []
      $scope.mappings = []

      # wait for the browser to render the DOM for the new HTML
      $timeout ->
        $scope.paths = domSearcher.collectSubPaths $scope.rootId, $scope.rootId
        $scope.selectedPath = $scope.paths[0]

    $scope.checkPage = ->
      $scope.paths = domSearcher.collectPaths()
      $scope.selectedPath = $scope.paths[0]

    $scope.scan = ->
      switch $scope.sourceMode
        when "local"
          $scope.mappings = domSearcher.collectContents $scope.selectedPath, $scope.rootId
        when "page"
          $scope.mappings = domSearcher.collectContents $scope.selectedPath

#      $scope.atomicMappings = $filter('filter')($scope.mappings, (mapping) -> mapping.atomic)
        

angular.module('innerPeace.controllers', [])
  .controller('SearchController', SearchController)
