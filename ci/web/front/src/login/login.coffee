'use strict'

window.Login = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}
	
	$scope.login = () ->
		rpc.makeRequest 'users', 'update', 'login', $scope.account, (error, result) ->
			if error?
				console.error error
			else
				# this will force a refresh, rather than do html5 pushstate
				window.location.href = '/'
]
