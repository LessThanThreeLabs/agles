'use strict'

window.Admin = ['$scope', '$location', '$routeParams', 'fileSuffixAdder', ($scope, $location, $routeParams, fileSuffixAdder) ->
	$scope.currentView = $routeParams.view ? 'users'

	$scope.menuOptionClick = (viewName) ->
		$scope.currentView = viewName

	$scope.$watch 'currentView', (newValue, oldValue) ->
		$location.search 'view', newValue
]


# window.AdminRepositories = ['$scope', '$location', 'initialState', 'rpc', 'events', ($scope, $location, initialState, rpc, events) ->
# 	$scope.orderByPredicate = 'name'
# 	$scope.orderByReverse = false
# 	$scope.repositories = []

# 	getRepositories = () ->
# 		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
# 			$scope.$apply () -> $scope.repositories = $scope.repositories.concat repositories

# 	handleAddedRepositoryUpdated = (data) -> $scope.$apply () ->
# 		$scope.repositories.push data

# 	handleRemovedRepositoryUpdate = (data) -> $scope.$apply () ->
# 		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
# 		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

# 	addRepositoryEvents = events.listen('users', 'repository added', initialState.user.id).setCallback(handleAddedRepositoryUpdated).subscribe()
# 	removeRepositoryEvents = events.listen('users', 'repository removed', initialState.user.id).setCallback(handleRemovedRepositoryUpdate).subscribe()
# 	$scope.$on '$destroy', addRepositoryEvents.unsubscribe
# 	$scope.$on '$destroy', removeRepositoryEvents.unsubscribe

# 	getRepositories()

# 	$scope.removeRepository = (repository) ->
# 		$location.path('/remove/repository').search
# 			id: repository.id
# 			name: repository.name

# 	$scope.addRepository = () ->
# 		$location.path('/add/repository').search({})
# ]


window.AdminUsers = ['$scope', 'initialState', 'rpc', 'events', ($scope, initialState, rpc, events) ->
	$scope.orderByPredicate = 'lastName'
	$scope.orderByReverse = false

	getUsers = () ->
		rpc.makeRequest 'users', 'read', 'getAllUsers', null, (error, users) ->
			$scope.$apply () -> $scope.users = users

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
]


# window.AdminAddMembers = ['$scope', 'rpc', ($scope, rpc) ->
# 	$scope.stage = 'first'
# 	$scope.modalVisible = false
# 	$scope.membersToAdd = {}
# 	$scope.showError = false

# 	$scope.$watch 'modalVisible', (newValue, oldValue) ->
# 		$scope.stage = 'first'
# 		$scope.membersToAdd = {}
# 		$scope.showError = false

# 	$scope.submit = () ->
# 		rpc.makeRequest 'users', 'create', 'inviteUsers', users: $scope.membersToAdd, (error) ->
# 			$scope.$apply () ->
# 				if error?
# 					$scope.showError = true
# 				else
# 					$scope.stage = 'second'
# 					$scope.showError = false
# ]
