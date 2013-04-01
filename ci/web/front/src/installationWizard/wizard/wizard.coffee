'use strict'

window.Wizard = ['$scope', '$location', '$routeParams', 'rpc', ($scope, $location, $routeParams, rpc) ->
	$scope.admin = {}

	syncToRouteParams = () ->
		$scope.stepNumber = $routeParams.step ? 1
	$scope.$on '$routeUpdate', syncToRouteParams
	syncToRouteParams()

	$scope.submitStepOne = () ->
		$scope.stepNumber = 2

	$scope.submitStepTwo = () ->
		console.log 'check validity'
		$scope.stepNumber = 3

	$scope.$watch 'stepNumber', (newValue, oldValue) ->
		$location.search 'step', newValue ? null
]

