'use strict'

window.Account = ['$scope', 'fileSuffixAdder', ($scope, fileSuffixAdder) ->

]

window.AccountBasic = ['$scope', 'accountInformation', 'socket', ($scope, accountInformation, socket) ->
	$scope.account =
		firstName: accountInformation.firstName
		lastName: accountInformation.lastName

	$scope.submit = () ->
		socket.makeRequest 'users', 'update', 'basic', $scope.account, (result) ->
			console.log 'result: ' + result
]

window.AccountPassword = ['$scope', 'socket', ($scope, socket) ->
	$scope.account = {}

	$scope.submit = () ->
		socket.makeRequest 'users', 'update', 'basic', $scope.account, (result) ->
			console.log 'result: ' + result
]

window.AccountSshKeys = ['$scope', 'socket', ($scope, socket) ->
	$scope.keys = [{alias: 'first', timestamp: 13928471}, {alias: 'second', timestamp: 13928471}, {alias: 'third', timestamp: 13928471}]
	
	$scope.addKey = {}
	$scope.addKey.modalVisible = false

	$scope.addKey.submit = () ->
		$scope.addKey.modalVisible = false
		console.log 
			alias: $scope.addKey.alias
			key: $scope.addKey.key
		resetValues()

	resetValues = () ->
		$scope.addKey.alias = ''
		$scope.addKey.key = ''
]
