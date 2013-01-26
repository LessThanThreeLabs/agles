window.Header = ['$scope', '$location', 'initialState', ($scope, $location, initialState) ->
	$scope.loggedIn = initialState.user.id?

	$scope.user =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	$scope.visitHome = () -> $location.path '/'
	$scope.visitLogin = () -> $location.path '/login'
	$scope.visitProfile = () -> $location.path '/account'
	$scope.visitAbout = () -> $location.path '/about'
]