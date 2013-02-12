'use strict'

window.Login = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}

	$scope.login = () ->
		rpc.makeRequest 'users', 'update', 'login', $scope.account, (error, result) ->
			$scope.$apply () ->
				if error?
					console.log error
					$scope.showError = true
				else
					# this will force a refresh, rather than do html5 pushstate
					window.location.href = '/'
]
