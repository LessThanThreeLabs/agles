window.Account = ['$scope', 'fileSuffixAdder', 'socket', ($scope, fileSuffixAdder, socket) ->
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'

	$scope.account = {}
	$scope.account.basic = {}
	$scope.account.password = {}

	$scope.basicSubmit = () ->
		console.log 'basic submit'
		console.log $scope.account.basic

	$scope.passwordSubmit = () ->
		console.log 'password submit'
		console.log $scope.account.password
]