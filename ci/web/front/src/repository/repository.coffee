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
	retrieveStages = (changeId) ->
		$scope.stages = null
		$scope.lines = null
		return if not changeId?

		socket.makeRequest 'buildConsoles', 'read', 'getBuildConsoles', changesQuery, (error, buildOutputs) ->
			if error? then console.error error
			else
				console.log buildOutputs
				# $scope.$apply () -> $scope.changes = $scope.changes.concat changes

	retrieveLines = (stageId) ->
		$scope.lines = null
		if stageId?
			$scope.lines = null
			setTimeout (() -> $scope.$apply () ->
				$scope.lines = (createRandomLine number for number in [1..300])
			), 250

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = $routeParams.id
	$scope.currentChangeId = $routeParams.id

	$scope.stageClick = (stage) ->
		$scope.currentStageId = stage.id

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		retrieveStages newValue

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		retrieveLines newValue
]















createRandomChange = (number) ->
	id: Math.floor Math.random() * 10000
	number: number
	status: if Math.random() > .25 then 'passed' else 'failed'


createRandomStage = (name) ->
	id: Math.floor Math.random() * 10000
	name: name
	status: if Math.random() > .25 then 'passed' else 'failed'

createRandomLine = (number) ->
	randString = () ->
		a = Math.random().toString(36).substr(2)
		a += Math.random().toString(36).substr(2) for number in [0..(Math.random() * 7)]
		return a

	number: number
	text: randString()