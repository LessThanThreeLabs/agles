'use strict'

window.About = ['$scope', 'fileSuffixAdder', ($scope, fileSuffixAdder) ->
	$scope.awesomeImageSource = fileSuffixAdder.addFileSuffix '/img/balling.jpg'
]