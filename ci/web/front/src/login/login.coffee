window.Login = ['$scope', 'socket', ($scope, socket) ->
	$scope.login = () ->
		socket.makeRequest 'users', 'update', 'login', $scope.account, (result) ->
			console.log 'result: ' + result
]
