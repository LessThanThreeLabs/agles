'use strict'

window.ResetPassword = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}
	
	$scope.resetPassword = () ->
		rpc.makeRequest 'users', 'update', 'resetPassword', $scope.account, (error) ->
			$scope.$apply () ->
				$scope.showError = true if error is 500
]
