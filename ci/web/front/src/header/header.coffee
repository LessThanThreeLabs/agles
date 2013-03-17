'use strict'

window.Header = ['$scope', '$location', 'initialState', 'rpc', ($scope, $location, initialState, rpc) ->
	$scope.loggedIn = initialState.loggedIn
	$scope.isAdmin = initialState.user.isAdmin

	$scope.feedback = {}
	$scope.feedback.modalVisible = false
	$scope.feedback.showSuccess = false

	$scope.visitHome = () -> $location.path('/').search({})

	$scope.submitFeedback = () ->
		requestParams =
			feedback: $scope.feedback.text
			userAgent: navigator.userAgent
			screen: window.screen
		rpc.makeRequest 'users', 'update', 'submitFeedback', requestParams

		$scope.feedback.showSuccess = true

	$scope.$watch 'feedback.modalVisible', (newValue, oldValue) ->
		if not newValue
			$scope.feedback.text = ''
			$scope.feedback.showSuccess = false
]


window.HeaderProfile = ['$scope', '$location', 'initialState', 'rpc', 'events', ($scope, $location, initialState, rpc, events) ->
	$scope.user =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	handleUpdate = (data) -> $scope.$apply () ->
		$scope.user.firstName = data.firstName
		$scope.user.lastName = data.lastName

	if $scope.loggedIn
		userEvents = events.listen('users', 'user name updated', initialState.user.id).setCallback(handleUpdate).subscribe()
		$scope.$on '$destroy', userEvents.unsubscribe

	$scope.profileDropdownOptions = [{title: 'Account', name: 'account'}, {title: 'Logout', name: 'logout'}]
	$scope.profileDropdownOptionClick = (profileOption) ->
		if profileOption is 'account' and $location.path() isnt '/account'
			$location.path('/account').search({})

		if profileOption is 'logout'
			performLogout()

	performLogout = () ->
		rpc.makeRequest 'users', 'update', 'logout', null, (error) ->
			# this will force a refresh, rather than do html5 pushstate
			window.location.href = '/'
]


window.HeaderRepositories = ['$scope', '$location', 'initialState', 'rpc', 'events', ($scope, $location, initialState, rpc, events) ->
	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () -> 
				$scope.repositoryDropdownOptions = $scope.repositoryDropdownOptions.concat (createDropdownOptionFromRepository repository for repository in repositories)

	createDropdownOptionFromRepository = (repository) ->
		title: repository.name
		name: repository.id

	handleRepositoryAdded = (data) -> $scope.$apply () ->
		$scope.repositoryDropdownOptions.push createDropdownOptionFromRepository data

	handleRepositoryRemoved = (data) -> $scope.$apply () ->
		repositoryToRemoveIndex = (index for dropdownOption, index in $scope.repositoryDropdownOptions when dropdownOption.name is data.id)[0]
		$scope.repositoryDropdownOptions.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	if $scope.loggedIn
		addRepositoryEvents = events.listen('users', 'repository added', initialState.user.id).setCallback(handleRepositoryAdded).subscribe()
		removeRepositoryEvents = events.listen('users', 'repository removed', initialState.user.id).setCallback(handleRepositoryRemoved).subscribe()
		$scope.$on '$destroy', addRepositoryEvents.unsubscribe
		$scope.$on '$destroy', removeRepositoryEvents.unsubscribe
	
	$scope.repositoryDropdownOptions = []
	getRepositories() if $scope.loggedIn

	$scope.repositoryDropdownOptionClick = (repositoryId) ->
		if $location.path() isnt '/repository/' + repositoryId
			$location.path('/repository/' + repositoryId).search({})
]


window.HeaderAdmin = ['$scope', '$location', ($scope, $location) ->
	$scope.visitAdmin = () -> 
		if $location.path() isnt '/admin'
			$location.path('/admin').search({})
]
