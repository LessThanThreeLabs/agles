'use strict'

window.RecoverPassword = ['$scope', 'socket', ($scope, socket) ->
	$scope.account = {}
	
	$scope.recoverPassword = () ->
		socket.makeRequest 'users', 'update', 'recoverPassword', $scope.account, (result) ->
			console.log 'result: ' + result
]