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


window.AccountSshKeys = ['$scope', 'rpc', 'events', 'initialState', ($scope, rpc, events, initialState) ->
	getKeys = () ->
		rpc.makeRequest 'users', 'read', 'getSshKeys', null, (error, keys) ->
			if error? then console.error error
			else $scope.$apply () -> $scope.keys = keys

	handleAddedKeyUpdated = (data) -> $scope.$apply () ->
		$scope.keys.push data

	handleRemovedKeyUpdate = (data) -> $scope.$apply () ->
		keyToRemoveIndex = (index for key, index in $scope.keys when key.id is data.id)[0]
		$scope.keys.splice keyToRemoveIndex, 1 if keyToRemoveIndex?

	addKeyEvents = events.listen('users', 'ssh pubkey added', initialState.user.id).setCallback(handleAddedKeyUpdated).subscribe()
	removeKeyEvents = events.listen('users', 'ssh pubkey removed', initialState.user.id).setCallback(handleRemovedKeyUpdate).subscribe()
	$scope.$on '$destroy', addKeyEvents.unsubscribe
	$scope.$on '$destroy', removeKeyEvents.unsubscribe

	getKeys()

	$scope.removeKey = (key) ->
		rpc.makeRequest 'users', 'update', 'removeSshKey', id: key.id, (error, result) ->
			if error? then console.error error
			else console.log result

]


window.AccountAddSshKeys = ['$scope', 'rpc', ($scope, rpc) ->
	addKey = () ->
		keyToAdd =
			alias: $scope.addKey.alias
			key: $scope.addKey.key
		rpc.makeRequest 'users', 'update', 'addSshKey', keyToAdd, (error, result) ->
			if error? then console.error error
			else console.log result

	$scope.addKey = {}
	$scope.modalVisible = false

	$scope.submit = () ->
		$scope.modalVisible = false
		addKey()
		resetValues()

	resetValues = () ->
		$scope.addKey = {}
]
