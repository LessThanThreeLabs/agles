window.Account = ['$scope', '$location', 'initialState', ($scope, $location, initialState) ->
	$scope.menuOptionClick = (option) ->
		console.log '>>>> ' + option
]