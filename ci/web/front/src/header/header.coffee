'use strict'

window.Header = ['$scope', '$location', 'initialState', 'socket', ($scope, $location, initialState, socket) ->
	$scope.user =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	# since components are shown depending on this boolean,
	# make sure to set it last
	$scope.loggedIn = initialState.user.id?

	$scope.visitHome = () -> $location.path '/'
	$scope.visitLogin = () -> $location.path '/login'
	$scope.visitAbout = () -> $location.path '/about'

	$scope.profileDropdownOptions = [{title: 'Account', name: 'account'}, {title: 'Logout', name: 'logout'}]
	$scope.profileDropdownOptionClick = (profileOption) ->
		if profileOption is 'account' then $location.path '/account'
		else console.log performLogout()

	$scope.repositoryDropdownOptions = [{title: 'Repository 1', name: 17}, {title: 'Repository 2', name: 18}]
	$scope.repositoryDropdownOptionClick = (repositoryId) ->
		$location.path '/repository/' + repositoryId

	performLogout = () ->
		socket.makeRequest 'users', 'update', 'logout', null, (error) ->
			# this will force a refresh, rather than do html5 pushstate
			window.location.href = '/'
]