'use strict'

window.CreateAccount = ['$scope', '$routeParams', 'initialState', 'rpc', ($scope, $routeParams, initialState, rpc) ->
	getEmailFromToken = () ->
		rpc.makeRequest 'users', 'create', 'getEmailFromToken', token: $routeParams.token, (error, email) ->
			$scope.$apply () -> $scope.account.email = email

	$scope.account = {}
	$scope.account.token = $routeParams.token
	getEmailFromToken()
	
	$scope.submit = () ->
		rpc.makeRequest 'users', 'create', 'createUser', $scope.account, (error, result) ->
			$scope.$apply () ->
				if error then $scope.showError = true
				else
					# this will force a refresh, rather than do html5 pushstate
					window.location.href = '/'
]
