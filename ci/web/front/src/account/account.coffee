'use strict'

window.Account = ['$scope', 'fileSuffixAdder', ($scope, fileSuffixAdder) ->
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'
]

window.AccountBasic = ['$scope', 'accountInformation', 'socket', ($scope, accountInformation, socket) ->
	$scope.firstName = accountInformation.firstName
	$scope.lastName = accountInformation.lastName
	$scope.submit = () ->
		console.log
			firstName: $scope.firstName
			lastName: $scope.lastName
]

window.AccountPassword = ['$scope', 'socket', ($scope, socket) ->
	$scope.submit = () ->
		console.log
			oldPassword: $scope.oldPassword
			newPassword: $scope.newPassword
			confirmPassword: $scope.confirmPassword
]

window.AccountSshKeys = ['$scope', 'socket', ($scope, socket) ->
	$scope.keys = [{alias: 'first', timestamp: 13928471}, {alias: 'second', timestamp: 13928471}, {alias: 'third', timestamp: 13928471}]
	
	$scope.addKey = {}

	$scope.addKey.modalVisible = false
	$scope.addKey.showModal = () -> $scope.addKey.modalVisible = true
	$scope.addKey.hideModal = () -> $scope.addKey.modalVisible = false
	$scope.addKey.submit = () ->
		$scope.addKey.hideModal()
		console.log 
			alias: $scope.addKey.alias
			key: $scope.addKey.key
		$scope.addKey.resetValues()
	$scope.addKey.resetValues = () ->
		$scope.addKey.alias = ''
		$scope.addKey.key = ''
]
