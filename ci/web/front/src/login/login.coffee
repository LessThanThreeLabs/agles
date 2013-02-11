'use strict'

window.Login = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}

	$scope.login = () ->
		rpc.makeRequest 'users', 'update', 'login', $scope.account, (error, result) ->
			console.error error if error?
			if error is 403
				$scope.$apply () -> $scope.showError = true
			else
				# this will force a refresh, rather than do html5 pushstate
				window.location.href = '/'
]
