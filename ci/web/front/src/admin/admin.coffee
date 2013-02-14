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

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			if error? then console.error error
			else $scope.$apply () -> $scope.repositories = repositories

	handleAddedRepositoryUpdated = (data) -> $scope.$apply () ->
		$scope.repositories.push data

	handleRemovedRepositoryUpdate = (data) -> $scope.$apply () ->
		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	# addRepositoryEvents = events.listen('users', 'repository added', initialState.user.id).setCallback(handleAddedKeyUpdated).subscribe()
	# removeRepositoryEvents = events.listen('users', 'repository removed', initialState.user.id).setCallback(handleRemovedKeyUpdate).subscribe()
	# $scope.$on '$destroy', addRepositoryEvents.unsubscribe
	# $scope.$on '$destroy', removeRepositoryEvents.unsubscribe

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

	$scope.members = (createMember number for number in [9001..9051])

	$scope.removeMember = (member) ->
		console.log 'need to remove member:'
		console.log member
]


createMember = (number) ->
	id: number
	email: "#{number}@email.com"
	firstName: "hello#{number}"
	lastName: "there#{number}"
	timestamp: Math.floor(Math.random() * 1000000000000)