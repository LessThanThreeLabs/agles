window.CreateAccount = ['$scope', 'fileSuffixAdder', ($scope, fileSuffixAdder) ->
	$scope.formErrorImageSource = fileSuffixAdder.addFileSuffix '/img/icons/error.png'

	$scope.createAccount = () ->
		console.log 'need to create account!'
		console.log $scope.account
]
