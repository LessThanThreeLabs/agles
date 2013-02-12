'use strict'

window.Admin = ['$scope', '$location', '$routeParams', 'fileSuffixAdder', ($scope, $location, $routeParams, fileSuffixAdder) ->
	$scope.menuOptions = [{title: 'Repositories', name: 'repositories'}, {title: 'Members', name: 'members'}]
	$scope.currentView = $routeParams.view ? 'repositories'

	$scope.menuOptionClick = (optionName) ->
		$scope.currentView = optionName

	$scope.$watch 'currentView', (newValue, oldValue) ->
		$location.search 'view', newValue
]


window.AdminRepositories = ['$scope', 'initialState', 'rpc', 'events', ($scope, initialState, rpc, events) ->
	# getRepositories = () ->
	# 	rpc.makeRequest 'repositories', 'read', 'getAllRepositories', null, (error, repositories) ->
	# 		if error? then console.error error
	# 		else $scope.$apply () -> $scope.repositories = repositories

	# handleAddedRepositoryUpdated = (data) -> $scope.$apply () ->
	# 	$scope.repositories.push data

	# handleRemovedRepositoryUpdate = (data) -> $scope.$apply () ->
	# 	repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
	# 	$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	# addRepositoryEvents = events.listen('repositories', 'repository added', initialState.user.id).setCallback(handleAddedKeyUpdated).subscribe()
	# removeRepositoryEvents = events.listen('repositories', 'repository removed', initialState.user.id).setCallback(handleRemovedKeyUpdate).subscribe()
	# $scope.$on '$destroy', addRepositoryEvents.unsubscribe
	# $scope.$on '$destroy', removeRepositoryEvents.unsubscribe

	# getRepositories()

	# $scope.removeRepository = (repository) ->
	# 	rpc.makeRequest 'repositories', 'delete', 'deleteRepository', id: repository.id, (error, result) ->
	# 		if error? then console.error error
	# 		else console.log result
]


window.AdminMembers = ['$scope', 'initialState', 'rpc', 'events', ($scope, initialState, rpc, events) ->
	$scope.orderByPredicate = 'lastName'
	$scope.orderByReverse = false

	# memberA =
	# 	id: 9001
	# 	email: 'awesome@email.com'
	# 	firstName: 'Jordan'
	# 	lastName: 'Potter'
	# 	timestamp: 1329489124
	# memberB =
	# 	id: 9002
	# 	email: 'cool@email.com'
	# 	firstName: 'Jonathan'
	# 	lastName: 'Chu'
	# 	timestamp: 12093812903
	# memberC =
	# 	id: 9003
	# 	email: 'cooler@email.com'
	# 	firstName: 'Ryan'
	# 	lastName: 'Scott'
	# 	timestamp: 23458901345
	# memberD =
	# 	id: 9004
	# 	email: 'coolest@email.com'
	# 	firstName: 'Brian'
	# 	lastName: 'Bland'
	# 	timestamp: 30981904111
	# $scope.members = [memberA, memberB, memberC, memberD]
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