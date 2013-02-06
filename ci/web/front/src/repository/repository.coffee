'use strict'

window.Repository = ['$scope', 'socket', ($scope, socket) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'
]


window.RepositoryChanges = ['$scope', '$location', '$routeParams', 'socket', ($scope, $location, $routeParams, socket) ->
	noMoreChangesToRetrieve = false
	waitingOnChanges = false
	numChangesToRequest = 100

	retrieveMoreChanges = () ->
		return if noMoreChangesToRetrieve or waitingOnChanges
		waitingOnChanges = true

		changesQuery =
			repositoryId: $routeParams.repositoryId
			group: 'all'
			query: $scope.query
			startIndex: $scope.changes.length
			numToRetrieve: numChangesToRequest
		socket.makeRequest 'changes', 'read', 'getChanges', changesQuery, (error, changes) ->
			if error? then console.error error
			else
				noMoreChangesToRetrieve = changes.length < numChangesToRequest
				$scope.$apply () -> $scope.changes = $scope.changes.concat changes
				waitingOnChanges = false

	$scope.changes = []
	$scope.query = ''

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = $routeParams.id ? null
	$scope.currentChangeId = $routeParams.id ? null

	retrieveMoreChanges()

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


window.RepositoryDetails = ['$scope', '$location', '$routeParams', 'socket', ($scope, $location, $routeParams, socket) ->
	retrieveStages = () ->
		$scope.stages = null
		$scope.lines = null
		return if not $scope.currentChangeId?

		socket.makeRequest 'buildConsoles', 'read', 'getBuildConsoles', changeId: $scope.currentChangeId, (error, buildConsoles) ->
			if error? then console.error error
			else $scope.$apply () -> $scope.stages = buildConsoles

	retrieveLines = () ->
		$scope.lines = []
		return if not $scope.currentStageId?

		socket.makeRequest 'buildConsoles', 'read', 'getLines', id: $scope.currentStageId, (error, lines) ->
			if error? then console.error error
			else
				$scope.$apply () -> 
					for lineNumber, lineText of lines
						$scope.lines[lineNumber-1] = lineText

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















createRandomStage = (name) ->
	id: Math.floor Math.random() * 10000
	name: name
	status: if Math.random() > .25 then 'passed' else 'failed'

createRandomLine = (number) ->
	randString = () ->
		a = '\x1b[' + (Math.round(Math.random() * 9) + 30) + ';' + (Math.round(Math.random() * 9) + 40) + 'm'
		a += Math.random().toString(36).substr(2)
		a += Math.random().toString(36).substr(2) for number in [0..(Math.random() * 7)]
		return a

	number: number
	text: randString()