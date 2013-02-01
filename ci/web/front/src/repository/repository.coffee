'use strict'

window.Repository = ['$scope', ($scope) ->
	$scope.name = 'awesome.git'
	$scope.link = 'git@getkoality.com:bblandATlessthanthreelabsDOTcom/koality.git'

	$scope.changes = (createRandomChange number for number in [0..137]).reverse()
	$scope.currentChange = null

	$scope.changeClick = (change) ->
		console.log 'change clicked!'
		$scope.currentChange = change

	$scope.$watch 'currentChange', (newValue, oldValue) ->
		console.log 'current change: ' + newValue
]

createRandomChange = (number) ->
	number: number
	status: if Math.random() > .5 then 'passed' else 'failed'