'use strict'

window.Header = ['$scope', '$location', 'initialState', ($scope, $location, initialState) ->
	$scope.loggedIn = initialState.loggedIn

	$scope.visitHome = () -> $location.path('/').search({})
]


window.HeaderProfile = ['$scope', '$location', 'initialState', 'rpc', 'events', ($scope, $location, initialState, rpc, events) ->
	$scope.user =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	handleUpdate = (data) -> $scope.$apply () ->
		console.log '~~~~'
		console.log data
		$scope.user.firstName = data.firstName
		$scope.user.lastName = data.lastName
	events.listen('users', 'user updated', initialState.user.id).setCallback(handleUpdate).subscribe()

	$scope.profileDropdownOptions = [{title: 'Account', name: 'account'}, {title: 'Logout', name: 'logout'}]
	$scope.profileDropdownOptionClick = (profileOption) ->
		if profileOption is 'account' then $location.path('/account').search({})
		if profileOption is 'logout' then performLogout()

	performLogout = () ->
		rpc.makeRequest 'users', 'update', 'logout', null, (error) ->
			if error? then console.error error
			else
				# this will force a refresh, rather than do html5 pushstate
				window.location.href = '/'
]


window.HeaderLogin = ['$scope', '$location', ($scope, $location) ->
	$scope.visitLogin = () -> $location.path('/login').search({})
]


window.HeaderRepositories = ['$scope', '$location', 'initialState', 'rpc', ($scope, $location, initialState, rpc) ->
	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			if error? then console.error error
			else $scope.$apply () -> $scope.repositoryDropdownOptions = (createDropdownOptionFromRepository repository for repository in repositories)

	createDropdownOptionFromRepository = (repository) ->
		title: repository.name
		name: repository.id
	
	getRepositories() if $scope.loggedIn

	$scope.repositoryDropdownOptionClick = (repositoryId) ->
		$location.path('/repository/' + repositoryId).search({})
]


window.HeaderAbout = ['$scope', '$location', 'initialState', ($scope, $location, initialState) ->
	$scope.visitAbout = () -> $location.path('/about').search({})
]