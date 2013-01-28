window.Account = ['$scope', 'fileSuffixAdder', 'socket', ($scope, fileSuffixAdder, socket) ->
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'
	$scope.account = {}
	$scope.account.basic = {}

	$scope.basicSubmit = () ->
		console.log 'basic submit'

	$scope.passwordSubmit = () ->
		console.log 'password submit'
]