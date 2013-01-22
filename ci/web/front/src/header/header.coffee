# TODO: this is vulnerable to minification?
window.Header = ($scope, $window) ->
	optionA =
		title: 'Jordan Potter'
	optionB =
		title: 'Repositories'
	optionC =
		title: 'About'
	$scope.options = [optionA, optionB, optionC]

	$scope.visitHome = () ->
		$window.location.href = '/'
