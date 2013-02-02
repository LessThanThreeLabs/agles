'use strict'

window.Repository = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'
]

window.RepositoryChanges = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	retrieveChanges = () ->
		$scope.changes = (createRandomChange number for number in [0..137]).reverse()
		$scope.currentChangeId ?= $scope.changes[0].id

		$scope.changes[0].status = 'queued'
		$scope.changes[1].status = 'running'
		$scope.changes[2].status = 'running'

	$scope.currentChangeId = $routeParams.id ? null
	retrieveChanges()

	$scope.changeClick = (change) ->
		$scope.currentChangeId = if $scope.currentChangeId is change.id then null else change.id

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'id', newValue


	$scope.scrolledToBottom = () ->
		console.log 'scrolled to bottom!!'
]

window.RepositoryDetails = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	$scope.$on '$routeUpdate', () ->
		console.log 'update to route!! ' + $routeParams.id
]















createRandomChange = (number) ->
	id: Math.floor Math.random() * 10000
	number: number
	status: if Math.random() > .25 then 'passed' else 'failed'
