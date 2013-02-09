'use strict'

window.Repository = ['$scope', ($scope) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'
]


window.RepositoryChanges = ['$scope', '$location', '$routeParams', 'rpc', 'events', ($scope, $location, $routeParams, rpc, events) ->
	noMoreChangesToRetrieve = false
	waitingOnChanges = false
	numChangesToRequest = 100

	retrieveMoreChanges = () ->
		return if noMoreChangesToRetrieve or waitingOnChanges
		waitingOnChanges = true

		changesQuery =
			repositoryId: parseInt $routeParams.repositoryId
			group: 'all'
			query: $scope.query
			startIndex: $scope.changes.length
			numToRetrieve: numChangesToRequest
		rpc.makeRequest 'changes', 'read', 'getChanges', changesQuery, (error, changes) ->
			if error? then console.error error
			else
				noMoreChangesToRetrieve = changes.length < numChangesToRequest
				$scope.$apply () -> $scope.changes = $scope.changes.concat changes
				waitingOnChanges = false

	$scope.changes = []
	$scope.query = ''

	handeChangeAdded = (data) -> $scope.$apply () ->
		$scope.changes.unshift data

	handleChangeStarted = (data) -> $scope.$apply () ->
		change = (change for change in $scope.changes when change.id is data.id)[0]
		change.status = data.status if change?

	handleChangeFinished = (data) -> $scope.$apply () ->
		change = (change for change in $scope.changes when change.id is data.id)[0]
		change.status = data.status if change?

	changeAddedEvents = events.listen('repositories', 'change added', $routeParams.repositoryId).setCallback(handeChangeAdded).subscribe()
	changeStartedEvents = events.listen('repositories', 'change started', $routeParams.repositoryId).setCallback(handleChangeStarted).subscribe()
	changeFinishedEvents = events.listen('repositories', 'change finished', $routeParams.repositoryId).setCallback(handleChangeFinished).subscribe()
	$scope.$on '$destroy', changeAddedEvents.unsubscribe
	$scope.$on '$destroy', changeStartedEvents.unsubscribe
	$scope.$on '$destroy', changeFinishedEvents.unsubscribe

	retrieveMoreChanges()

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = $routeParams.id ? null
	$scope.currentChangeId = $routeParams.id ? null

	$scope.changeClick = (change) ->
		$scope.currentChangeId = change.id

	$scope.scrolledToBottom = () ->
		retrieveMoreChanges()

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'id', newValue

	$scope.$watch 'query', (newValue, oldValue) ->
		$scope.changes = []
		retrieveMoreChanges()
]


window.RepositoryDetails = ['$scope', '$location', '$routeParams', 'crazyAnsiText', 'rpc', ($scope, $location, $routeParams, crazyAnsiText, rpc) ->
	retrieveStages = () ->
		$scope.stages = null
		$scope.lines = null
		return if not $scope.currentChangeId?

		rpc.makeRequest 'buildConsoles', 'read', 'getBuildConsoles', changeId: $scope.currentChangeId, (error, buildConsoles) ->
			if error? then console.error error
			else $scope.$apply () -> $scope.stages = buildConsoles

	retrieveLines = () ->
		$scope.lines = []
		return if not $scope.currentStageId?

		rpc.makeRequest 'buildConsoles', 'read', 'getLines', id: $scope.currentStageId, (error, lines) ->
			if error? then console.error error
			else
				$scope.$apply () -> 
					for lineNumber, lineText of lines
						$scope.lines[lineNumber-1] = crazyAnsiText.makeCrazy lineText

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = $routeParams.id
	$scope.currentChangeId = $routeParams.id

	$scope.stageClick = (stage) ->
		$scope.currentStageId = stage.id

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$scope.currentStageId = null
		retrieveStages newValue

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		retrieveLines newValue
]
