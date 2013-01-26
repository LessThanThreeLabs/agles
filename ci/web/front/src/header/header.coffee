window.Header = ['$scope', '$location', 'initialState', ($scope, $location, initialState) ->
	$scope.loggedIn = initialState.user.id?

	$scope.user =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	$scope.visitHome = () -> $location.path '/'
	$scope.visitLogin = () -> $location.path '/login'
	$scope.visitProfile = () -> $location.path '/account'
	$scope.repositoryClick = () -> $scope.repositoryDropdownOpen = !$scope.repositoryDropdownOpen
	$scope.visitAbout = () -> $location.path '/about'

	optionA = 
		title: 'Blah 1'
		name: 'blah1'
	optionB =
		title: 'Blah 2'
		name: 'blah2'
	$scope.repositoryDropdownOptions = [optionA, optionB]
	$scope.repositoryDropdownOptionClick = (dropdownOption) ->
		console.log dropdownOption
]