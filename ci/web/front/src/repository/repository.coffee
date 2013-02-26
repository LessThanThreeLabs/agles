'use strict'

window.Repository = ['$scope', ($scope) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'
]


window.RepositoryChanges = ['$scope', '$location', '$routeParams', 'changesRpc', 'events', 'integerConverter', ($scope, $location, $routeParams, changesRpc, events, integerConverter) ->
	$scope.changes = []

	$scope.search = {}
	$scope.search.mode = 'all'
	$scope.search.namesQuery = ''

	getGroupFromMode = () ->
		if $scope.search.mode is 'all' or $scope.search.mode is 'me'
			return $scope.search.mode
		if $scope.search.namesQuery is ''
			return 'all'
		return null

	getNamesFromNamesQuery = () ->
		names = $scope.search.namesQuery.toLowerCase().split ' '
		names = names.filter (name) -> name.length > 0
		return if names.length > 0 then names else null

	handleInitialChanges = (error, changes) -> $scope.$apply () -> 
		$scope.changes = $scope.changes.concat changes
		$scope.currentChangeId ?= $scope.changes[0].id if $scope.changes[0]?

	handleMoreChanges = (error, changes) -> $scope.$apply () -> 
		$scope.changes = $scope.changes.concat changes

	getInitialChanges = () ->
		$scope.changes = []
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), 0, handleInitialChanges

	getMoreChanges = () ->
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), $scope.changes.length, handleMoreChanges

	doesChangeMatchQuery = (change) ->
		return true if $scope.namesQuery is ''
		return (change.submitter.firstName.toLowerCase() in getNamesFromNamesQuery()) or
			(change.submitter.lastName.toLowerCase() in getNamesFromNamesQuery())

	handeChangeAdded = (data) -> $scope.$apply () ->
		if doesChangeMatchQuery data
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

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = integerConverter.toInteger $routeParams.change
	$scope.currentChangeId = integerConverter.toInteger $routeParams.change

	$scope.searchModeClicked = (mode) ->
		$scope.search.mode = mode
		$scope.search.namesQuery = '' if mode isnt 'search'

	$scope.changeClick = (change) ->
		$scope.currentChangeId = change.id

	$scope.scrolledToBottom = () ->
		getMoreChanges()

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'change', newValue

	$scope.$watch 'search.mode', (newValue, oldValue) ->
		getInitialChanges() if newValue isnt oldValue

	$scope.$watch 'search.namesQuery', (newValue, oldValue) ->
		getInitialChanges() if newValue isnt oldValue

	getInitialChanges()
]


window.RepositoryDetails = ['$scope', '$location', '$routeParams', 'crazyAnsiText', 'rpc', 'events', 'integerConverter', ($scope, $location, $routeParams, crazyAnsiText, rpc, events, integerConverter) ->
	isStageIdInStages = (stageId) ->
		return false if not $scope.stages?
		stage = (stage for stage in $scope.stages when stage.id is stageId)[0]
		return stage?

	retrieveMetadata = () ->
		$scope.metadata = {}
		return if not $scope.currentChangeId?

		rpc.makeRequest 'changes', 'read', 'getMetadata', id: $scope.currentChangeId, (error, metadata) ->
			$scope.$apply () -> $scope.metadata = metadata

	retrieveStages = () ->
		$scope.stages = null
		$scope.lines = null
		return if not $scope.currentChangeId?

		rpc.makeRequest 'buildConsoles', 'read', 'getBuildConsoles', changeId: $scope.currentChangeId, (error, buildConsoles) ->
			$scope.$apply () ->
				$scope.stages = buildConsoles

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
		$scope.currentStageId = if stage? then stage.id else null

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		retrieveMetadata()
		retrieveStages()
		updateBuildConsoleAddedListener()
		updateBuildConsoleStatusListener()

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		if isStageIdInStages($scope.currentStageId) or not $scope.currentStageId?
			retrieveLines()
			updateAddedLineListener()
		$location.search 'stage', newValue
]
