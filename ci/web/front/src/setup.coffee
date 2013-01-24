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

		makeRequestHandler = (resource, requestType, functionName, data, callback) ->
			assert resource.indexOf('.') is -1 and requestType.indexOf('.') is -1 and functionName.indexOf('.') is -1
			socket.emit "#{resource}.${requestType}.#{functionName}", data, callback
			console.log "socket request made for #{resource} - #{requestType} - #{functionName}"

		subscribeHandler = (resource, resourceId, eventName, callback) ->
			makeRequestHandler resource, 'subscribe', eventName, resourceId: resourceId, (error, eventToListenFor) ->
				if error?
					console.error error
				else
					socket.on eventToListenFor, callback
					console.log "subscribed to event #{resource} - #{eventName}"

		unsubscribeHandler = (resource, resourceId, eventName) ->
			makeRequestHandler resource, 'unsubscribe', eventName, resourceId: resourceId, (error) ->
				console.error if error?
			console.log "unsubscribed to event #{resource} - #{eventName}"

		makeRequest: makeRequestHandler
		subscribe: subscribeHandler
		unsubscribe: unsubscribeHandler
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
