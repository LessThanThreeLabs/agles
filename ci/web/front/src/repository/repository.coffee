'use strict'

window.Repository = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	retrieveChanges = () ->
		$scope.changes = (createRandomChange number for number in [0..137]).reverse()
		$scope.currentChangeId ?= $scope.changes[0].id

	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'

	$scope.currentChangeId = $routeParams.id ? null
	retrieveChanges()

	$scope.changeClick = (change) ->
		if $scope.currentChangeId is change.id
			$scope.currentChangeId = null
		else
			$scope.currentChangeId = change.id

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'id', newValue
]

createRandomChange = (number) ->
	id: Math.floor Math.random() * 10000
	number: number
	status: if Math.random() > .5 then 'passed' else 'failed'
