'use strict'

window.Admin = ['$scope', '$location', '$routeParams', 'fileSuffixAdder', ($scope, $location, $routeParams, fileSuffixAdder) ->
	$scope.menuOptions = [{title: 'Repositories', name: 'repositories'}, {title: 'Members', name: 'members'}]
	$scope.currentView = $routeParams.view ? 'repositories'

	$scope.menuOptionClick = (optionName) ->
		$scope.currentView = optionName

	$scope.$watch 'currentView', (newValue, oldValue) ->
		$location.search 'view', newValue
]


window.AdminRepositories = ['$scope', '$location', 'initialState', 'rpc', 'events', ($scope, $location, initialState, rpc, events) ->
	$scope.orderByPredicate = 'name'
	$scope.orderByReverse = false
	$scope.repositories = []

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () -> $scope.repositories = $scope.repositories.concat repositories

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

	$scope.addRepository = () ->
		$location.path('/add/repository').search({})
]


window.AdminMembers = ['$scope', 'initialState', 'rpc', 'events', ($scope, initialState, rpc, events) ->
	$scope.orderByPredicate = 'lastName'
	$scope.orderByReverse = false
	$scope.members = []

	getMembers = () ->
		rpc.makeRequest 'users', 'read', 'getAllUsers', null, (error, members) ->
			$scope.$apply () -> $scope.members = $scope.members.concat members

	handleMemberAdded = (data) -> $scope.$apply () ->
		$scope.members.push data

	handleMemberRemoved = (data) -> $scope.$apply () ->
		userToRemoveIndex = (index for member, index in $scope.members when member.id is data.id)[0]
		$scope.members.splice userToRemoveIndex, 1 if userToRemoveIndex?

	addMemberEvents = events.listen('users', 'user added', initialState.user.id).setCallback(handleMemberAdded).subscribe()
	removeMemberEvents = events.listen('users', 'user removed', initialState.user.id).setCallback(handleMemberRemoved).subscribe()
	$scope.$on '$destroy', addMemberEvents.unsubscribe
	$scope.$on '$destroy', removeMemberEvents.unsubscribe

	getMembers()

	$scope.removeMember = (member) ->
		rpc.makeRequest 'users', 'delete', 'deleteUser', id: member.id
]


window.AdminAddMembers = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.stage = 'first'
	$scope.modalVisible = false
	$scope.membersToAdd = {}
	$scope.showError = false

	$scope.$watch 'modalVisible', (newValue, oldValue) ->
		$scope.stage = 'first'
		$scope.membersToAdd = {}
		$scope.showError = false

	$scope.submit = () ->
		rpc.makeRequest 'users', 'create', 'inviteUsers', users: $scope.membersToAdd, (error) ->
			$scope.$apply () ->
				if error?
					$scope.showError = true
				else
					$scope.stage = 'second'
					$scope.showError = false
]
