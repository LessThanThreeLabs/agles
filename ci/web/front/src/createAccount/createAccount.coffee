'use strict'

window.CreateAccount = ['$scope', 'fileSuffixAdder', 'socket', ($scope, fileSuffixAdder, socket) ->
	$scope.account = {}

	$scope.createAccount = () ->
		socket.makeRequest 'users', 'create', 'createAccount', $scope.account, (result) ->
			console.log 'result: ' + result
]
