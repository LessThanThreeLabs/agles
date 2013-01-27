window.Header = ['$scope', '$location', 'initialState', ($scope, $location, initialState) ->
	$scope.loggedIn = initialState.user.id?

	$scope.user =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	$scope.visitHome = () -> $location.path '/'
	$scope.visitLogin = () -> $location.path '/login'
	$scope.profileClick = () -> $scope.profileDropdownOpen = !$scope.profileDropdownOpen
	$scope.repositoryClick = () -> $scope.repositoryDropdownOpen = !$scope.repositoryDropdownOpen
	$scope.visitAbout = () -> $location.path '/about'

	$scope.profileDropdownOptions = [{title: 'Account', name: 'account'}, {title: 'Logout', name: 'logout'}]
	$scope.profileDropdownOptionClick = (profileOption) ->
		if profileOption is 'account' then $location.path '/account'
		else console.log 'need to handle logout!'

	$scope.repositoryDropdownOptions = [{title: 'Repository 1', name: 17}, {title: 'Repository 2', name: 18}]
	$scope.repositoryDropdownOptionClick = (repositoryId) ->
		$location.path '/repository/' + repositoryId
]