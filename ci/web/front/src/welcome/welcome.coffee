window.Welcome = ['$scope', 'fileSuffixAdder', ($scope, fileSuffixAdder) ->
	$scope.awesomeImageSource = fileSuffixAdder.addFileSuffix '/img/awesomeFace.png'
]