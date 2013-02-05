'use strict'

window.Login = ['$scope', 'socket', ($scope, socket) ->
	$scope.account = {}
	
	$scope.login = () ->
		socket.makeRequest 'users', 'update', 'login', $scope.account, (error, result) ->
			if error?
				console.error error
			else
				# this will force a refresh, rather than do html5 pushstate
				window.location.href = '/'
]
