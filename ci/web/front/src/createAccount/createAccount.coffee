'use strict'

window.CreateAccount = ['$scope', '$routeParams', 'rpc', ($scope, $routeParams, rpc) ->
	getEmailFromToken = () ->
		rpc.makeRequest 'users', 'read', 'getEmailFromToken', token: $routeParams.token, (error, email) ->
			$scope.$apply () ->
				if error?
					console.error error
					$scope.errorText = 'Error retrieving email. Please contact your administator.'
				else
					$scope.account.email = email

	$scope.account = {}
	getEmailFromToken()
	
	$scope.submit = () ->
		console.log 'submit clicked'
]
