'use strict'

window.Account = ['$scope', '$location', '$routeParams', 'fileSuffixAdder', ($scope, $location, $routeParams, fileSuffixAdder) ->
	$scope.currentView = $routeParams.view ? 'basic'

	$scope.menuOptionClick = (optionName) ->
		$scope.currentView = optionName

	$scope.$watch 'currentView', (newValue, oldValue) ->
		$location.search 'view', newValue
]


window.AccountBasic = ['$scope', 'initialState', 'rpc', ($scope, initialState, rpc) ->
	$scope.account =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	$scope.submit = () ->
		rpc.makeRequest 'users', 'update', 'changeBasicInformation', $scope.account, (error, result) ->
			if error?
				console.error
			console.log 'result: ' + result
]


window.AccountPassword = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}

	$scope.submit = () ->
		rpc.makeRequest 'users', 'update', 'changePassword', $scope.account, (error, result) ->
			if error?
				console.error error
			console.log 'result: ' + result
]


window.AccountSshKeys = ['$scope', 'rpc', ($scope, rpc) ->
	getKeys = () ->
		rpc.makeRequest 'users', 'read', 'getSshKeys', null, (error, keys) ->
			if error? then console.error error
			else $scope.$apply () -> $scope.keys = keys

	addKey = () ->
		keyToAdd =
			alias: $scope.addKey.alias
			key: $scope.addKey.key
		rpc.makeRequest 'users', 'update', 'addSshKey', keyToAdd, (error, result) ->
			if error? then console.error error
			else console.log result

	getKeys()

	$scope.addKey = {}
	$scope.addKey.modalVisible = false

	$scope.addKey.submit = () ->
		$scope.addKey.modalVisible = false
		addKey()
		resetValues()

	resetValues = () ->
		$scope.addKey.alias = ''
		$scope.addKey.key = ''

	$scope.removeKey = (key) ->
		rpc.makeRequest 'users', 'update', 'removeSshKey', id: key.id, (error, result) ->
			if error? then console.error error
			else console.log result
]
