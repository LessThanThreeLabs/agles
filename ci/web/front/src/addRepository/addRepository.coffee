'use strict'

window.AddRepository = ['$scope', '$location', 'socket', ($scope, $location, socket) ->
	$scope.repository = {}

	$scope.addRepository = () ->
		socket.makeRequest 'repositories', 'create', 'createRepository', $scope.repository, (result) ->
			console.log 'result: ' + result
]