window.Login = ['$scope', 'socket', ($scope, socket) ->
	$scope.account = {}
	
	$scope.login = () ->
		socket.makeRequest 'users', 'update', 'login', $scope.account, (result) ->
			console.log 'result: ' + result
]
