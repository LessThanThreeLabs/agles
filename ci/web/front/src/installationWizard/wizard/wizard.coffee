'use strict'

window.Wizard = ['$scope', '$location', '$routeParams', 'rpc', 'integerConverter', ($scope, $location, $routeParams, rpc, integerConverter) ->
	$scope.website = {}
	$scope.admin = {}

	syncToRouteParams = () ->
		$scope.stepNumber = integerConverter.toInteger $routeParams.step ? 0
	$scope.$on '$routeUpdate', syncToRouteParams
	syncToRouteParams()

	$scope.goToStepOne = () ->
		$scope.stepNumber = 1

	$scope.goToStepTwo = () ->
		console.log 'need to validate 1 -> 2'
		$scope.stepNumber = 2

	$scope.goToStepThree = () ->
		rpc.makeRequest 'users', 'create', 'validateInitialAdminUser', $scope.admin, (error) ->
			$scope.$apply () ->
				if error?
					$scope.errorText = error
				else
					$scope.stepNumber = 3

	$scope.goToStepFour = () ->
		rpc.makeRequest 'users', 'create', 'validateInitialAdminToken', $scope.admin, (error) ->
			$scope.$apply () ->
				if error?
					$scope.errorText = error
				else
					$scope.stepNumber = 4

	$scope.goToStepFive = () ->
		console.log 'need to validate 4 -> 5'
		$scope.stepNumber = 5

	$scope.goToKoality = () ->
		window.location.href = '/'

	$scope.$watch 'stepNumber', (newValue, oldValue) ->
		$location.search 'step', newValue ? null
]

