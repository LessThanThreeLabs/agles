'use strict'

window.Account = ['$scope', '$location', '$routeParams', 'fileSuffixAdder', ($scope, $location, $routeParams, fileSuffixAdder) ->
	$scope.menuOptions = [{title: 'Basic', name: 'basic'}, {title: 'Password', name: 'password'}, {title: 'SSH Keys', name: 'sshKeys'}]
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
		rpc.makeRequest 'users', 'update', 'changeBasicInformation', $scope.account
]


window.AccountPassword = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}

	$scope.submit = () ->
		rpc.makeRequest 'users', 'update', 'changePassword', $scope.account
]


window.AccountSshKeys = ['$scope', 'rpc', 'events', 'initialState', ($scope, rpc, events, initialState) ->
	getKeys = () ->
		rpc.makeRequest 'users', 'read', 'getSshKeys', null, (error, keys) ->
			$scope.$apply () -> $scope.keys = keys

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
		rpc.makeRequest 'users', 'update', 'removeSshKey', id: key.id
]


window.AccountAddSshKeys = ['$scope', 'rpc', ($scope, rpc) ->
	addKey = () ->
		keyToAdd =
			alias: $scope.addKey.alias
			key: $scope.addKey.key
		rpc.makeRequest 'users', 'update', 'addSshKey', keyToAdd

	$scope.addKey = {}
	$scope.modalVisible = false

	$scope.submit = () ->
		$scope.modalVisible = false
		addKey()
		resetValues()

	resetValues = () ->
		$scope.addKey = {}
]
