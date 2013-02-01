'use strict'

window.Repository = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'

	$scope.changes = (createRandomChange number for number in [0..137]).reverse()
	$scope.currentChangeId = $routeParams.id

	$scope.changeClick = (change) ->
		$scope.currentChangeId = change.id

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		$location.search 'id', newValue ? null
]

createRandomChange = (number) ->
	id: Math.floor Math.random() * 10000
	number: number
	status: if Math.random() > .5 then 'passed' else 'failed'
	