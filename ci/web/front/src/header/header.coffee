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
		if profileOption is 'logout' then performLogout()

	$scope.repositoryDropdownOptions = [{title: 'awesome.git', name: 'awesome'}, 
		{title: 'neat.git', name: 'neat'}, {title: 'Add Repository', name: '*add*repository*'}]
	$scope.repositoryDropdownOptionClick = (repositoryName) ->
		if repositoryName is '*add*repository*'
			$location.path('/add/repository').search(null)
		else	
			$location.path('/repository/' + repositoryName).search(null)

	performLogout = () ->
		socket.makeRequest 'users', 'update', 'logout', null, (error) ->
			# this will force a refresh, rather than do html5 pushstate
			window.location.href = '/'
]