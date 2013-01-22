angular.module('koality.service', []).
	factory('fileSuffixAdder', ['$window', ($window) ->
		return addFileSuffix: (fileSrc) -> 
			lastPeriodIndex = fileSrc.lastIndexOf '.'
			return fileSrc if lastPeriodIndex is -1
			return fileSrc.substr(0, lastPeriodIndex) + $window.fileSuffix + fileSrc.substr(lastPeriodIndex)
	])


angular.module('koality.directive', [])


angular.module('koality.filter', [])


angular.module('koality', ['koality.service', 'koality.directive', 'koality.filter']).
	config(['$routeProvider', ($routeProvider) ->
		$routeProvider.
			when('/welcome', 
				templateUrl: "html/welcome#{fileSuffix}.html"
				controller: Welcome
			).
			when('/create/account', 
				templateUrl: "html/createAccount#{fileSuffix}.html"
				controller: CreateAccount
			).
			when('/repository/:repositoryId', 
				templateUrl: "html/repository#{fileSuffix}.html"
				controller: Repository
			).
			otherwise(
				redirectTo: '/welcome'
			)
	]).
	run(() ->
		console.log 'initialization happens here'
	)
