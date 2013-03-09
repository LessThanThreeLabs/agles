'use strict'

window.Repository = ['$scope', '$routeParams', 'rpc', 'integerConverter', ($scope, $routeParams, rpc, integerConverter) ->
	retrieveRepositoryInformation = () ->
		rpc.makeRequest 'repositories', 'read', 'getMetadata', id: $routeParams.repositoryId, (error, repositoryInformation) ->
			$scope.$apply () ->
				$scope.repository = repositoryInformation

	retrieveCurrentChangeInformation = () ->
		$scope.currentChangeInformation = null
		return if not $scope.currentChangeId?

		requestData =
			repositoryId: integerConverter.toInteger $routeParams.repositoryId
			id: $scope.currentChangeId
		rpc.makeRequest 'changes', 'read', 'getMetadata', requestData, (error, changeInformation) ->
			$scope.$apply () -> $scope.currentChangeInformation = changeInformation

	retrieveCurrentStageInformation = () ->
		$scope.currentStageInformation = null
		return if not $scope.currentStageId?

		requestData =
			repositoryId: integerConverter.toInteger $routeParams.repositoryId
			id: $scope.currentStageId
		rpc.makeRequest 'buildConsoles', 'read', 'getBuildConsole', requestData, (error, stageInformation) ->
			$scope.$apply () -> $scope.currentStageInformation = stageInformation

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = integerConverter.toInteger $routeParams.change
		$scope.currentStageId = integerConverter.toInteger $routeParams.stage
	$scope.currentChangeId = integerConverter.toInteger $routeParams.change
	$scope.currentStageId = integerConverter.toInteger $routeParams.stage

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		retrieveCurrentChangeInformation()

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		retrieveCurrentStageInformation()

	retrieveRepositoryInformation()
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
		$scope.changes = changes
		if $scope.changes.length is 0
			$scope.currentChangeId = null
		else if $scope.changes[0]?
			$scope.currentChangeId ?= $scope.changes[0].id

	handleMoreChanges = (error, changes) -> $scope.$apply () -> 
		$scope.changes = $scope.changes.concat changes

	getInitialChanges = () ->
		$scope.changes = []
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), 0, handleInitialChanges

	getMoreChanges = () ->
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), $scope.changes.length, handleMoreChanges

	doesChangeMatchQuery = (change) ->
		return true if not getNamesFromNamesQuery()?
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

	$scope.searchModeClicked = (mode) ->
		$scope.search.mode = mode
		$scope.search.namesQuery = '' if mode isnt 'search'

	$scope.changeClick = (change) ->
		$scope.currentChangeId = change.id

	$scope.scrolledToBottom = () ->
		getMoreChanges()

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'change', newValue

	$scope.$watch 'search', ((newValue, oldValue) -> getInitialChanges()), true
]


window.RepositoryStages = ['$scope', '$location', '$routeParams', 'rpc', 'events', 'integerConverter', ($scope, $location, $routeParams, rpc, events, integerConverter) ->
	$scope.stages = []

	isStageIdInStages = (stageId) ->
		stage = (stage for stage in $scope.stages when stage.id is stageId)[0]
		return stage?

	getMostImportantStageWithTypeAndName = (type, name) ->
		mostImportantStage = null

		for potentialStage in $scope.stages
			continue if potentialStage.type isnt type or potentialStage.name isnt name

			if not mostImportantStage?
				mostImportantStage = potentialStage
			else
				if potentialStage.status is 'failed' and mostImportantStage.status is 'failed'
					mostImportantStage = potentialStage if potentialStage.id < mostImportantStage.id
				else if potentialStage.status is 'failed' and mostImportantStage.status isnt 'failed'
					mostImportantStage = potentialStage
				else if potentialStage.status isnt 'failed' and mostImportantStage.status isnt 'failed'
					mostImportantStage = potentialStage if potentialStage.id < mostImportantStage.id

		return mostImportantStage

	isMirrorStage = (stage1, stage2) ->
		return false if not stage1? or not stage2?
		return stage1.type is stage2.type and stage1.name is stage2.name

	retrieveStages = () ->
		$scope.stages = []
		return if not $scope.currentChangeId?

		rpc.makeRequest 'buildConsoles', 'read', 'getBuildConsoles', changeId: $scope.currentChangeId, (error, buildConsoles) ->
			$scope.$apply () ->
				$scope.stages = buildConsoles
				$scope.currentStageId = null if not isStageIdInStages $scope.currentStageId

	handleBuildConsoleAdded = (data) -> $scope.$apply () ->
		$scope.stages.push data

	handleBuildConsoleStatusUpdate = (data) -> $scope.$apply () ->
		stage = (stage for stage in $scope.stages when stage.id is data.id)[0]
		stage.status = data.status if stage?

		if stage.status is 'failed' and isMirrorStage stage, $scope.currentStageInformation
			$scope.currentStageId = stage.id

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

	$scope.stageClick = (stage) ->
		$scope.currentStageId = if stage? then stage.id else null

	$scope.stageSort = (stage) ->
		if stage.type is 'setup'
			return 1000 + stage.orderNumber
		else if stage.type is 'compile'
			return 2000 + stage.orderNumber
		else if stage.type is 'test'
			return 3000 + stage.orderNumber
		else
			console.error 'Cannot sort stage'
			return 4000

	$scope.shouldStageBeVisible = (stage) ->
		return true if stage.id is $scope.currentStageId
		return false if isMirrorStage stage, $scope.currentStageInformation
		return true if stage.id is getMostImportantStageWithTypeAndName(stage.type, stage.name).id
		return false

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		retrieveStages()
		updateBuildConsoleAddedListener()
		updateBuildConsoleStatusListener()

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		$location.search 'stage', newValue
]


window.RepositoryStageDetails = ['$scope', '$location', '$routeParams', 'rpc', 'events', 'integerConverter', ($scope, $location, $routeParams, rpc, events, integerConverter) ->
	retrieveLines = () ->
		$scope.lines = []
		return if not $scope.currentStageId?
		$scope.spinnerOn = true

		rpc.makeRequest 'buildConsoles', 'read', 'getLines', id: $scope.currentStageId, (error, lines) ->
			$scope.$apply () ->
				$scope.spinnerOn = false
				for lineNumber, lineText of lines
					addLine lineNumber, lineText

	addLine = (lineNumber, lineText) ->
		$scope.lines[lineNumber-1] = lineText

	handleLinesAdded = (data) -> $scope.$apply () ->
		$scope.lines ?= []
		for lineNumber, lineText of data
			addLine lineNumber, lineText

	addedLineEvents = null
	updateAddedLineListener = () ->
		if addedLineEvents?
			addedLineEvents.unsubscribe()
			addedLineEvents = null

		if $scope.currentStageId?
			addedLineEvents = events.listen('buildConsoles', 'new output', $scope.currentStageId).setCallback(handleLinesAdded).subscribe()
	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		retrieveLines()
		updateAddedLineListener()
]
