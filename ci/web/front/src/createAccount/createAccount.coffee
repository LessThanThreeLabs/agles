window.CreateAccount = ['$scope', 'fileSuffixAdder', 'socket', ($scope, fileSuffixAdder, socket) ->
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'

	# $scope.account =
	# 	email: 'a@gmail.com'
	# 	password: 'aoeuaoeu1'
	# 	confirmPassword: 'aoeuaoeu1'
	# 	firstName: 'Jordan'
	# 	lastName: 'Potter'

	$scope.createAccount = () ->
		console.log 'need to create account!'
		console.log $scope.account

		socket.makeRequest 'users', 'create', 'createAccount', $scope.account, (result) ->
			console.log 'result: ' + result
]
