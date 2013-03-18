'use strict'

window.Admin = ['$scope', '$location', '$routeParams', 'fileSuffixAdder', ($scope, $location, $routeParams, fileSuffixAdder) ->
	$scope.currentView = $routeParams.view ? 'users'

	$scope.menuOptionClick = (viewName) ->
		$scope.currentView = viewName

	$scope.$watch 'currentView', (newValue, oldValue) ->
		$location.search 'view', newValue
]


window.AdminUsers = ['$scope', 'initialState', 'rpc', 'events', ($scope, initialState, rpc, events) ->
	$scope.orderByPredicate = 'lastName'
	$scope.orderByReverse = false

	$scope.addUsers = {}
	$scope.addUsers.modalVisible = false

	getUsers = () ->
		rpc.makeRequest 'users', 'read', 'getAllUsers', null, (error, users) ->
			$scope.$apply () -> $scope.users = users

	inviteUsers = () ->
		rpc.makeRequest 'users', 'create', 'inviteUsers', emails: $scope.addUsers.emails, (error) ->
			$scope.$apply () ->
				if error? then $scope.addUsers.showError = true
				else
					$scope.addUsers.modalVisible = false
					$scope.addUsers.showError = false
					$scope.addUsers.emails = ''

	handleUserAdded = (data) -> $scope.$apply () ->
		$scope.users.push data

	handleUserRemoved = (data) -> $scope.$apply () ->
		userToRemoveIndex = (index for user, index in $scope.users when user.id is data.id)[0]
		$scope.users.splice userToRemoveIndex, 1 if userToRemoveIndex?

	addUserEvents = events.listen('users', 'user created', initialState.user.id).setCallback(handleUserAdded).subscribe()
	removeUserEvents = events.listen('users', 'user removed', initialState.user.id).setCallback(handleUserRemoved).subscribe()
	$scope.$on '$destroy', addUserEvents.unsubscribe
	$scope.$on '$destroy', removeUserEvents.unsubscribe

	getUsers()

	$scope.removeUser = (user) ->
		rpc.makeRequest 'users', 'delete', 'deleteUser', id: user.id

	$scope.submitEmails = () ->
		inviteUsers()
]


window.AdminRepositories = ['$scope', '$location', 'initialState', 'rpc', 'events', ($scope, $location, initialState, rpc, events) ->
	$scope.orderByPredicate = 'name'
	$scope.orderByReverse = false

	$scope.addRepository = {}
	$scope.addRepository.stage = 'first'
	$scope.addRepository.modalVisible = false

	$scope.removeRepository = {}
	$scope.removeRepository.modalVisible = false

	$scope.publicKey = {}
	$scope.publicKeyVisible = false

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () -> $scope.repositories = repositories

	handleAddedRepositoryUpdate = (data) -> $scope.$apply () ->
		$scope.repositories.push data

	handleRemovedRepositoryUpdate = (data) -> $scope.$apply () ->
		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	addRepositoryEvents = events.listen('users', 'repository added', initialState.user.id).setCallback(handleAddedRepositoryUpdate).subscribe()
	removeRepositoryEvents = events.listen('users', 'repository removed', initialState.user.id).setCallback(handleRemovedRepositoryUpdate).subscribe()
	$scope.$on '$destroy', addRepositoryEvents.unsubscribe
	$scope.$on '$destroy', removeRepositoryEvents.unsubscribe

	getRepositories()

	$scope.openRemoveRepository = (repository) ->
		$scope.removeRepository.id = repository.id
		$scope.removeRepository.name = repository.name
		$scope.removeRepository.tokenToMatch = Math.random().toString(36).substr(2)
		$scope.removeRepository.modalVisible = true

	$scope.submitRemoveRepository = () ->
		return if $scope.removeRepository.token isnt $scope.removeRepository.tokenToMatch

		rpc.makeRequest 'repositories', 'delete', 'deleteRepository', 
			id: $scope.removeRepository.id
			password: $scope.removeRepository.password
		$scope.removeRepository.modalVisible = false

	$scope.getSshKey = () ->
		rpc.makeRequest 'repositories', 'create', 'getSshPublicKey', $scope.addRepository, (error, sshPublicKey) ->
			$scope.$apply () ->
				$scope.addRepository.publicKey = sshPublicKey
				$scope.addRepository.stage = 'second'

	$scope.createRepository = () ->
		rpc.makeRequest 'repositories', 'create', 'createRepository', $scope.addRepository, (error, repositoryId) ->
			$scope.$apply () -> $scope.addRepository.modalVisible = false

	resetAddRepositoryValues = () ->
		$scope.addRepository.stage = 'first'
		$scope.addRepository.name = null
		$scope.addRepository.forwardUrl = null
		$scope.addRepository.publicKey = null

	$scope.showPublicKey = (repository) ->
		rpc.makeRequest 'repositories', 'read', 'getPublicKey', id: repository.id, (error, publicKey) ->
			$scope.$apply () ->
				$scope.publicKey.key = publicKey
				$scope.publicKey.modalVisible = true

	$scope.$watch 'addRepository.modalVisible', (newValue, oldValue) ->
		resetAddRepositoryValues() if not newValue
]
