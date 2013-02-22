'use strict'

window.ResetPassword = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}
	
	$scope.resetPassword = () ->
		rpc.makeRequest 'users', 'update', 'resetPassword', $scope.account, (error) ->
			$scope.$apply () -> 
				if error?
					$scope.showSuccess = false
					$scope.showError = true
				else 
					$scope.showSuccess = true
					$scope.showError = false
]
