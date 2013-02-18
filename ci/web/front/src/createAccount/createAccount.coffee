'use strict'

window.CreateAccount = ['$scope', '$routeParams', 'rpc', ($scope, $routeParams, rpc) ->
	getEmailFromToken = () ->
		rpc.makeRequest 'users', 'read', 'getEmailFromToken', token: $scope.account.token, (error, email) ->
			$scope.$apply () ->
				if error?
					console.error error
					$scope.errorText = 'Error retrieving email. Please contact your administator.'
				else
					$scope.account.email = email

	$scope.account = {}
	$scope.account.token = $routeParams.token
	getEmailFromToken()
	
	$scope.submit = () ->
		rpc.makeRequest 'users', 'create', 'createUser', $scope.account, (error, result) ->
			if error?
				console.error error
				$scope.errorText = 'Unexpected error. Please contact your administator.'
			else
				# this will force a refresh, rather than do html5 pushstate
				window.location.href = '/'
]
