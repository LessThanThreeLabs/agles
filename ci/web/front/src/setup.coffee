angular.module('koality.service', []).
	factory('initialState', ['$window', ($window) ->
		fileSuffix: $window.fileSuffix
		csrfToken: $window.csrfToken
	]).
	factory('fileSuffixAdder', ['initialState', (initialState) ->
		return addFileSuffix: (fileSrc) -> 
			lastPeriodIndex = fileSrc.lastIndexOf '.'
			return fileSrc if lastPeriodIndex is -1
			return fileSrc.substr(0, lastPeriodIndex) + initialState.fileSuffix + fileSrc.substr(lastPeriodIndex)
	]).
	factory('socket', ['$location', 'initialState', ($location, initialState) ->
		socket = io.connect "//#{$location.host()}?csrfToken=#{initialState.csrfToken}", resource: 'socket'
		return makeRequest: (resource, requestType, functionName, data, callback) ->
			console.log 'need to make a request!'
			callback 'ok'
	])


angular.module('koality.directive', [])


angular.module('koality.filter', [])


angular.module('koality', ['koality.service', 'koality.directive', 'koality.filter']).
	config(['$routeProvider', ($routeProvider) ->
		$routeProvider.
			when('/welcome', 
				templateUrl: "/html/welcome#{fileSuffix}.html"
				controller: Welcome
			).
			when('/create/account', 
				templateUrl: "/html/createAccount#{fileSuffix}.html"
				controller: CreateAccount
			).
			when('/repository/:repositoryId', 
				templateUrl: "/html/repository#{fileSuffix}.html"
				controller: Repository
			).
			otherwise(
				redirectTo: '/welcome'
			)
	]).
	config(['$locationProvider', ($locationProvider) ->
		$locationProvider.html5Mode true
	]).
	run(() ->
		console.log 'initialization happens here'
	)
