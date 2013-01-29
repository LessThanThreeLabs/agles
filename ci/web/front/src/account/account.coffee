'use strict'

window.Account = ['$scope', 'fileSuffixAdder', 'accountInformation', 'socket', ($scope, fileSuffixAdder, accountInformation, socket) ->
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'

	$scope.account = {}
	$scope.account.basic = {}
	$scope.account.basic.firstName = accountInformation.firstName
	$scope.account.basic.lastName = accountInformation.lastName
	$scope.account.password = {}
	$scope.account.sshKey = {}

	$scope.sshKeys = [{alias: 'first', timestamp: 13928471}, {alias: 'second', timestamp: 13928471}, {alias: 'third', timestamp: 13928471}]

	$scope.basicSubmit = () ->
		console.log 'basic submit'
		console.log $scope.account.basic

	$scope.passwordSubmit = () ->
		console.log 'password submit'
		console.log $scope.account.password

	$scope.addSshKey = () ->
		console.log 'add ssh key'
		console.log $scope.account.sshKey

	# $scope.displayModal = true
	$scope.modalClosed = () ->
		console.log 'closed!'
	# 	$scope.$apply () -> $scope.displayModal = false
]