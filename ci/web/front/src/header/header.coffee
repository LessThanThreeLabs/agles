'use strict'

window.Header = ['$scope', '$location', 'initialState', 'socket', ($scope, $location, initialState, socket) ->
	$scope.loggedIn = initialState.user.id?

	$scope.user =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	$scope.visitHome = () -> $location.path('/').search(null)
	$scope.visitLogin = () -> $location.path('/login').search(null)
	$scope.visitAbout = () -> $location.path('/about').search(null)

	$scope.profileDropdownOptions = [{title: 'Account', name: 'account'}, {title: 'Logout', name: 'logout'}]
	$scope.profileDropdownOptionClick = (profileOption) ->
		if profileOption is 'account' then $location.path('/account').search(null)
		else console.log performLogout()

	$scope.repositoryDropdownOptions = [{title: 'Repository 1', name: 17}, {title: 'Repository 2', name: 18}]
	$scope.repositoryDropdownOptionClick = (repositoryId) ->
		$location.path('/repository/' + repositoryId).search(null)

	performLogout = () ->
		socket.makeRequest 'users', 'update', 'logout', null, (error) ->
			# this will force a refresh, rather than do html5 pushstate
			window.location.href = '/'
]