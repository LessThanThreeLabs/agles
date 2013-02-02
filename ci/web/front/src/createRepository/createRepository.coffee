'use strict'

window.CreateRepository = ['$scope', '$location', 'socket', ($scope, $location, socket) ->
	$scope.repository = {}

	$scope.createRepository = () ->
		socket.makeRequest 'repositories', 'create', 'createRepository', $scope.repository, (result) ->
			console.log 'result: ' + result
]