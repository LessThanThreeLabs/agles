'use strict'

window.Repository = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'
]

window.RepositoryChanges = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	retrieveChanges = () ->
		maxChanges = 9001
		max = maxChanges - $scope.changes.length
		min = maxChanges - $scope.changes.length - 100

		setTimeout (() ->			
			$scope.$apply () ->
				$scope.changes = $scope.changes.concat (createRandomChange number for number in [min..max].reverse())
				$scope.currentChangeId ?= $scope.changes[0].id

				$scope.changes[0].status = 'queued'
				$scope.changes[1].status = 'running'
				$scope.changes[2].status = 'running'
		), 250

	$scope.changes = []
	$scope.currentChangeId = $routeParams.id ? null
	retrieveChanges()

	$scope.changeClick = (change) ->
		$scope.currentChangeId = if $scope.currentChangeId is change.id then null else change.id

	$scope.$on '$routeUpdate', () ->
		$scope.currentChangeId = $routeParams.id

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'id', newValue

	$scope.scrolledToBottom = () ->
		retrieveChanges()

	$scope.$watch 'query', (newValue, oldValue) ->
		console.log 'query changed: ' + newValue
]

window.RepositoryDetails = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	retrieveStages = (changeId) ->
		$scope.stages = null
		$scope.lines = null
		if changeId?
			$scope.stages = null
			setTimeout (() -> $scope.$apply () ->
				$scope.stages = (createRandomStage 'blah ' + number for number in [0..8])
			), 250

	retrieveLines = (stageId) ->
		$scope.lines = null
		if stageId?
			$scope.lines = null
			setTimeout (() -> $scope.$apply () ->
				$scope.lines = (createRandomLine number for number in [1..300])
			), 250

	$scope.$on '$routeUpdate', () ->
		retrieveStages $routeParams.id
	retrieveStages $routeParams.id

	$scope.stageClick = (stage) ->
		$scope.currentStageId = if $scope.currentStageId is stage.id then null else stage.id

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