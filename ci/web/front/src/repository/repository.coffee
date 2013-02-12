'use strict'

window.Repository = ['$scope', ($scope) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'
]


window.RepositoryChanges = ['$scope', '$location', '$routeParams', 'rpc', 'events', 'integerConverter', ($scope, $location, $routeParams, rpc, events, integerConverter) ->
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
			$scope.$apply () -> 
				if error? 
					console.error error
				else
					noMoreChangesToRetrieve = changes.length < numChangesToRequest
					$scope.changes = $scope.changes.concat changes
					$scope.currentChangeId ?= $scope.changes[0].id
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
		$scope.currentChangeId = integerConverter.toInteger $routeParams.change
	$scope.currentChangeId = integerConverter.toInteger $routeParams.change

	$scope.changeClick = (change) ->
		$scope.currentChangeId = change.id

	$scope.scrolledToBottom = () ->
		retrieveMoreChanges()

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'change', newValue

	$scope.$watch 'query', (newValue, oldValue) ->
		$scope.changes = []
		retrieveMoreChanges()
]


window.RepositoryDetails = ['$scope', '$location', '$routeParams', 'crazyAnsiText', 'rpc', 'events', 'integerConverter', ($scope, $location, $routeParams, crazyAnsiText, rpc, events, integerConverter) ->
	isStageIdInStages = (stageId) ->
		return false if not $scope.stages?
		stage = (stage for stage in $scope.stages when stage.id is stageId)[0]
		return stage?

	retrieveStages = () ->
		$scope.stages = null
		$scope.lines = null
		return if not $scope.currentChangeId?

		rpc.makeRequest 'buildConsoles', 'read', 'getBuildConsoles', changeId: $scope.currentChangeId, (error, buildConsoles) ->
			$scope.$apply () ->
				if error? then console.error error
				else $scope.stages = buildConsoles

				if isStageIdInStages $scope.currentStageId
					retrieveLines()
					updateAddedLineListener()
				else
					$scope.currentStageId = null

	retrieveLines = () ->
		$scope.lines = []
		return if not $scope.currentStageId?
		return if not isStageIdInStages $scope.currentStageId

		rpc.makeRequest 'buildConsoles', 'read', 'getLines', id: $scope.currentStageId, (error, lines) ->
			$scope.$apply () ->
				if error?
					console.error error
				else
					for lineNumber, lineText of lines
						addLine lineNumber, lineText

	addLine = (lineNumber, lineText) ->
		$scope.lines[lineNumber-1] = crazyAnsiText.makeCrazy lineText

	handleBuildConsoleAdded = (data) -> $scope.$apply () ->
		$scope.stages ?= []
		$scope.stages.push data

	handleBuildConsoleStatusUpdate = (data) -> $scope.$apply () ->
		stage = (stage for stage in $scope.stages when stage.id is data.id)[0]
		stage.status = data.status if stage?

	handleLinesAdded = (data) -> $scope.$apply () ->
		$scope.lines ?= []
		for lineNumber, lineText of data
			addLine lineNumber, lineText

	buildConsoleAddedEvents = null
	updateBuildConsoleAddedListener = () ->
		if buildConsoleAddedEvents?
			buildConsoleAddedEvents.unsubscribe()
			buildConsoleAddedEvents = null

		if $scope.currentChangeId?
			buildConsoleAddedEvents = events.listen('changes', 'new build console', $scope.currentChangeId).setCallback(handleBuildConsoleAdded).subscribe()
	$scope.$on '$destroy', () -> buildConsoleAddedEvents.unsubscribe() if buildConsoleAddedEvents?

	buildConsoleStatusUpdateEvents = null
	updateBuildConsoleStatusListener = () ->
		if buildConsoleStatusUpdateEvents?
			buildConsoleStatusUpdateEvents.unsubscribe()
			buildConsoleStatusUpdateEvents = null

		if $scope.currentChangeId?
			buildConsoleStatusUpdateEvents = events.listen('changes', 'return code added', $scope.currentChangeId).setCallback(handleBuildConsoleStatusUpdate).subscribe()
	$scope.$on '$destroy', () -> buildConsoleStatusUpdateEvents.unsubscribe() if buildConsoleStatusUpdateEvents?

	addedLineEvents = null
	updateAddedLineListener = () ->
		if addedLineEvents?
			addedLineEvents.unsubscribe()
			addedLineEvents = null

		if $scope.currentStageId?
			addedLineEvents = events.listen('buildConsoles', 'new output', $scope.currentStageId).setCallback(handleLinesAdded).subscribe()
	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = integerConverter.toInteger $routeParams.change
		$scope.currentStageId = integerConverter.toInteger $routeParams.stage
	$scope.currentChangeId = integerConverter.toInteger $routeParams.change
	$scope.currentStageId = integerConverter.toInteger $routeParams.stage

	$scope.stageClick = (stage) ->
		$scope.currentStageId = stage.id

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		retrieveStages()
		updateBuildConsoleAddedListener()
		updateBuildConsoleStatusListener()

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		if isStageIdInStages($scope.currentStageId) or not $scope.currentStageId?
			retrieveLines()
			updateAddedLineListener()
		$location.search 'stage', newValue
]
