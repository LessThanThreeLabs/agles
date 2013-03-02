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
		$scope.members.push data

	handleUserRemoved = (data) -> $scope.$apply () ->
		userToRemoveIndex = (index for user, index in $scope.users when user.id is data.id)[0]
		$scope.members.splice userToRemoveIndex, 1 if userToRemoveIndex?

	addUserEvents = events.listen('users', 'user added', initialState.user.id).setCallback(handleUserAdded).subscribe()
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

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () -> $scope.repositories = repositories

	handleAddedRepositoryUpdated = (data) -> $scope.$apply () ->
		$scope.repositories.push data

	handleRemovedRepositoryUpdate = (data) -> $scope.$apply () ->
		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	addRepositoryEvents = events.listen('users', 'repository added', initialState.user.id).setCallback(handleAddedRepositoryUpdated).subscribe()
	removeRepositoryEvents = events.listen('users', 'repository removed', initialState.user.id).setCallback(handleRemovedRepositoryUpdate).subscribe()
	$scope.$on '$destroy', addRepositoryEvents.unsubscribe
	$scope.$on '$destroy', removeRepositoryEvents.unsubscribe

	getRepositories()

	$scope.removeRepository = (repository) ->
		$location.path('/remove/repository').search
			id: repository.id
			name: repository.name

	$scope.getSshKey = () ->
		requestParams = 
			name: $scope.addRepository.name
			forwardUrl: $scope.addRepository.forwardUrl
		rpc.makeRequest 'repositories', 'create', 'getSshPublicKey', requestParams, (error, sshPublicKey) ->
			$scope.$apply () ->
				$scope.addRepository.publicKey = sshPublicKey
				$scope.addRepository.stage = 'second'
]
