window.Login = ['$scope', 'fileSuffixAdder', 'socket', ($scope, fileSuffixAdder, socket) ->
	$scope.account =
		email: 'a@gmail.com'
		password: 'aoeuaoeu1'
		rememberMe: 'yes'

	$scope.login = () ->
		socket.makeRequest 'users', 'update', 'login', $scope.account, (result) ->
			console.log 'result: ' + result
]
