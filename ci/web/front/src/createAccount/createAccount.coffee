'use strict'

window.CreateAccount = ['$scope', 'fileSuffixAdder', 'socket', ($scope, fileSuffixAdder, socket) ->
	$scope.account = {}
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'

	$scope.createAccount = () ->
		socket.makeRequest 'users', 'create', 'createAccount', $scope.account, (result) ->
			console.log 'result: ' + result
]
