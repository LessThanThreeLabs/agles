'use strict'

window.Account = ['$scope', '$location', '$routeParams', 'initialState', ($scope, $location, $routeParams, initialState) ->
	$scope.name = initialState.user.firstName + ' ' + initialState.user.lastName
	$scope.currentView = $routeParams.view ? 'My Account'

	$scope.menuOptionClick = (viewName) ->
		$scope.currentView = viewName

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
	$scope.orderByPredicate = 'alias'
	$scope.orderByReverse = false

	getKeys = () ->
		keyA =
			alias: 'Some awesome alias'
			timestamp: 38974124
		keyB =
			alias: 'Another awesome alias'
			timestamp: 128312839018
		$scope.keys = [keyA, keyB]
		# rpc.makeRequest 'users', 'read', 'getSshKeys', null, (error, keys) ->
		# 	$scope.$apply () -> $scope.keys = keys

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
		rpc.makeRequest 'users', 'update', 'addSshKey', $scope.addKey

	$scope.addKey = {}
	$scope.modalVisible = false

	$scope.submit = () ->
		$scope.modalVisible = false
		addKey()
		$scope.addKey = {}
]
