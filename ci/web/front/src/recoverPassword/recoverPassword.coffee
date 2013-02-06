'use strict'

window.RecoverPassword = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}
	
	$scope.recoverPassword = () ->
		rpc.makeRequest 'users', 'update', 'recoverPassword', $scope.account, (result) ->
			console.log 'result: ' + result
]
