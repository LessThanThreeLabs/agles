window.SignUp = ($scope, $http) ->
	$scope.user = {}

	$scope.submit = () ->
		$http.post('/reachOut', $scope.user).success (result) ->
			if result is 'ok'
				$scope.showSuccess = true
			else
				$scope.showError = true
			