window.Header = ['$scope', '$location', ($scope, $location) ->
	optionA =
		title: 'Jordan Potter'
	optionB =
		title: 'Repositories'
	optionC =
		title: 'About'
	$scope.options = [optionA, optionB, optionC]

	$scope.visitHome = () ->
		$location.path '/'
]