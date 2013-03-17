'use strict'

window.Login = ['$scope', 'rpc', 'cookieExtender', ($scope, rpc, cookieExtender) ->
	$scope.account = {}

	redirectToHome = () ->
		# this will force a refresh, rather than do html5 pushstate
		window.location.href = '/'

	$scope.login = () ->
		rpc.makeRequest 'users', 'update', 'login', $scope.account, (error, result) ->
			$scope.$apply () ->
				if error? then $scope.showError = true
				else
					if $scope.account.rememberMe is 'yes'
						cookieExtender.extendCookie (error) ->
							console.error error if error?
							redirectToHome()
					else
						redirectToHome()

	$scope.$watch 'account', (() -> $scope.showError = false), true
]
