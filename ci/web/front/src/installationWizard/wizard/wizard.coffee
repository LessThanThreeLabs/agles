'use strict'

window.Wizard = ['$scope', '$location', '$routeParams', 'rpc', ($scope, $location, $routeParams, rpc) ->
	$scope.admin = {}

	syncToRouteParams = () ->
		$scope.stepNumber = $routeParams.step ? 0
	$scope.$on '$routeUpdate', syncToRouteParams
	syncToRouteParams()

	$scope.goToStepOne = () ->
		$scope.stepNumber = 1

	$scope.goToStepTwo = () ->
		console.log 'check validity'
		$scope.stepNumber = 2

	$scope.$watch 'stepNumber', (newValue, oldValue) ->
		$location.search 'step', newValue ? null

	$scope.$watch 'admin', ((newValue, oldValue) ->
		console.log $scope.admin
	), true
]

