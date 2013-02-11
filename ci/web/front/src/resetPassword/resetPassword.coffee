'use strict'

window.ResetPassword = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}
	
	$scope.resetPassword = () ->
		rpc.makeRequest 'users', 'update', 'resetPassword', $scope.account, (error) ->
			if error is 500 then $scope.$apply () -> $scope.showError = true
]
