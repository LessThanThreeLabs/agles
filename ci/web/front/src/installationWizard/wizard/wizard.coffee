'use strict'

window.Wizard = ['$scope', '$location', '$routeParams', 'rpc', 'integerConverter', ($scope, $location, $routeParams, rpc, integerConverter) ->
	$scope.website = {}
	$scope.admin = {}
	$scope.aws = {}

	$scope.$on '$routeUpdate', () ->
		$scope.stepNumber = integerConverter.toInteger $routeParams.step ? 0
	$scope.stepNumber = 0

	$scope.goToStepOne = () ->
		$scope.stepNumber = 1

	$scope.goToStepTwo = () ->
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
		_createInitialAdmin = () ->
			rpc.makeRequest 'users', 'create', 'createInitialAdmin', $scope.admin, (error) ->
				$scope.$apply () ->
					if error?
						$scope.errorText = error
					else
						_setDomainName()

		_setDomainName = () ->
			rpc.makeRequest 'systemSettings', 'update', 'setWebsiteSettings', $scope.website, (error) ->
				$scope.$apply () ->
					if error?
						$scope.errorText = error
					else
						_setAwsKeys()

		_setAwsKeys = () ->
			rpc.makeRequest 'systemSettings', 'update', 'setAwsKeys', $scope.aws, (error) ->
				$scope.$apply () ->
					if error?
						$scope.errorText = error
					else
						_setDeploymentInitialized()

		_setDeploymentInitialized = () ->
			rpc.makeRequest 'systemSettings', 'update', 'setDeploymentInitialized', null, (error) ->
				$scope.$apply () ->
					if error?
						$scope.errorText = error
					else
						$scope.stepNumber = 5			

		_createInitialAdmin()

	$scope.goToKoality = () ->
		window.location.href = '/'

	$scope.$watch 'stepNumber', (newValue, oldValue) ->
		$location.search 'step', newValue ? null
]

