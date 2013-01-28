'use strict'

window.Account = ['$scope', 'fileSuffixAdder', 'accountInformation', 'socket', ($scope, fileSuffixAdder, accountInformation, socket) ->
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'

	$scope.account = {}
	$scope.account.basic = {}
	$scope.account.basic.firstName = accountInformation.firstName
	$scope.account.basic.lastName = accountInformation.lastName
	$scope.account.password = {}

	$scope.basicSubmit = () ->
		console.log 'basic submit'
		console.log $scope.account.basic

	$scope.passwordSubmit = () ->
		console.log 'password submit'
		console.log $scope.account.password
]