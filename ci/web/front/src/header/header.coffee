window.Header = ($scope) ->
	optionA =
		title: 'blah1'
	optionB =
		title: 'blah2'
	optionC =
		title: 'blah3'
	$scope.options = [optionA, optionB, optionC]
	console.log $scope.options

