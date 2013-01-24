angular.module('koality.service', []).
	factory('initialState', ['$window', ($window) ->
		fileSuffix: if $window.fileSuffix is '' then null else $window.fileSuffix
		csrfToken: if $window.csrfToken is '' then null else $window.csrfToken
		user:
			id: if isNaN(parseInt($window.accountInformation?.userId)) then null else parseInt($window.accountInformation?.userId)
			email: if $window.accountInformation?.email is '' then null else $window.accountInformation?.email
			firstName: if $window.accountInformation?.firstName is '' then null else $window.accountInformation?.firstName
			lastName: if $window.accountInformation?.lastName is '' then null else $window.accountInformation?.lastName
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


angular.module('koality.directive', []).
	directive('unselectable', () ->
		return (scope, element, attributes) ->
			element.addClass 'unselectable'
	)
	.directive('focused', () ->
		return (scope, element, attributes) ->
			element.focus()
	)	


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
