'use strict'

angular.module('koality.service', []).
	factory('localStorage', ['$window', ($window) ->
		return window.localStorage
	]).
	factory('initialState', ['$window', ($window) ->
		toReturn =
			fileSuffix: if $window.fileSuffix is '' then null else $window.fileSuffix
			csrfToken: if $window.csrfToken is '' then null else $window.csrfToken
			user:
				id: if isNaN(parseInt($window.accountInformation?.id)) then null else parseInt($window.accountInformation.id)
				email: if $window.accountInformation?.email is '' then null else $window.accountInformation?.email
				firstName: if $window.accountInformation?.firstName is '' then null else $window.accountInformation?.firstName
				lastName: if $window.accountInformation?.lastName is '' then null else $window.accountInformation?.lastName
				isAdmin: $window.accountInformation?.isAdmin
		toReturn.loggedIn = toReturn.user.id?
		return Object.freeze toReturn
	]).
	factory('fileSuffixAdder', ['initialState', (initialState) ->
		return addFileSuffix: (fileSrc) ->
			lastPeriodIndex = fileSrc.lastIndexOf '.'
			return fileSrc if lastPeriodIndex is -1
			return fileSrc.substr(0, lastPeriodIndex) + initialState.fileSuffix + fileSrc.substr(lastPeriodIndex)
	]).
	factory('integerConverter', [() ->
		return toInteger: (integerAsString) ->
			if typeof integerAsString is 'number'
				if integerAsString isnt Math.floor(integerAsString) then return null
				else return integerAsString

			return null if typeof integerAsString isnt 'string'
			return null if integerAsString.indexOf('.') isnt -1

			integer = parseInt integerAsString
			return null if isNaN integer
			return integer
	]).
	factory('ansiparse', ['$window', ($window) ->
		return parse: (text) ->
			return '<span class="ansi">' + $window.ansiparse(text) + '</span>'
	]).
	factory('cookieExtender', ['$http', ($http) ->
		return extendCookie: (callback) ->
			successHandler = (data, status, headers, config) ->
				callback()
			errorHandler = (data, status, headers, config) ->
				callback 'unable to extend cookie expiration'

			$http.post('/extendCookieExpiration').success(successHandler).error(errorHandler)
	]).
	factory('socket', ['$window', '$location', 'initialState', ($window, $location, initialState) ->
		socket = io.connect "//#{$location.host()}?csrfToken=#{initialState.csrfToken}", resource: 'socket'
		previousEventToCallbacks = {}

		makeRequest: (resource, requestType, methodName, data, callback) ->
			assert.ok typeof resource is 'string' and typeof requestType is 'string' and typeof methodName is 'string'
			assert.ok resource.indexOf('.') is -1 and requestType.indexOf('.') is -1
			socket.emit "#{resource}.#{requestType}", {method: methodName, args: data}, (error, response) ->
				if error?
					console.error "#{resource}.#{requestType} - #{methodName}"
					console.error error
				switch error
					when 400, 404, 500 then window.location.href = '/unexpectedError'
					when 403 then window.location.href = '/invalidPermissions'
					else callback error, response if callback?

		respondTo: (eventName, callback) ->
			if not previousEventToCallbacks[eventName]?
				socket.on eventName, callback
				previousEventToCallbacks[eventName] = [callback]
			else
				for otherCallback in previousEventToCallbacks[eventName]
					return if callback is otherCallback

				socket.on eventName, callback
				previousEventToCallbacks[eventName].push callback
	]).
	factory('rpc', ['socket', (socket) ->
		makeRequest: socket.makeRequest
	]).
	factory('events', ['socket', 'integerConverter', (socket, integerConverter) ->
		class EventListener
			constructor: (@resource, @eventName, id) ->
				@_callback = null
				@id = integerConverter.toInteger id

			setCallback: (callback) =>
				assert.ok callback?
				@_callback = callback
				return @

			subscribe: () =>
				assert.ok @_callback?
				socket.makeRequest @resource, 'subscribe', @eventName, id: @id, (error, eventToListenFor) =>
					if error? then console.error error
					else socket.respondTo eventToListenFor, (data) =>
						@_callback data if @_callback?
				return @

			unsubscribe: () =>
				@_callback = null
				socket.makeRequest @resource, 'unsubscribe', @eventName, id: @id, (error) ->
					console.error if error?
				return @

		listen: (resource, eventName, id) ->
			return new EventListener resource, eventName, id
	]).
	factory('changesRpc', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		NUM_CHANGES_TO_REQUEST = 100
		noMoreChangesToRequest = false

		currentNameQuery = null
		currentCallback = null
		nextNameQuery = null
		nextCallback = null

		createChangesQuery = (repositoryId, group, names, startIndex) ->
			repositoryId: repositoryId
			group: group
			names: names
			startIndex: startIndex
			numToRetrieve: NUM_CHANGES_TO_REQUEST

		shiftChangesRequest = () ->
			if not nextNameQuery?
				currentNameQuery = null
				currentCallback = null
			else
				currentNameQuery = nextNameQuery
				currentCallback = nextCallback
				nextNameQuery = null
				nextCallback = null

				retrieveMoreChanges()

		retrieveMoreChanges = () ->
			assert.ok currentNameQuery?
			assert.ok currentCallback?

			noMoreChangesToRequest = false if currentNameQuery.startIndex is 0

			if noMoreChangesToRequest
				shiftChangesRequest()
			else
				rpc.makeRequest 'changes', 'read', 'getChanges', currentNameQuery, (error, changes) ->
					noMoreChangesToRequest = changes.length < NUM_CHANGES_TO_REQUEST
					currentCallback error, changes
					shiftChangesRequest()

		return queueRequest: (repositoryId, group, names, startIndex, callback) ->
			repositoryId = integerConverter.toInteger repositoryId

			assert.ok typeof repositoryId is 'number'
			assert.ok not group? or (typeof group is 'string' and (group is 'all' or group is 'me'))
			assert.ok not names? or (typeof names is 'object')
			assert.ok (group? and not names?) or (not group? and names?)
			assert.ok typeof startIndex is 'number'
			assert.ok typeof callback is 'function'

			if currentNameQuery?
				nextNameQuery = createChangesQuery repositoryId, group, names, startIndex
				nextCallback = callback
			else
				currentNameQuery = createChangesQuery repositoryId, group, names, startIndex
				currentCallback = callback
				retrieveMoreChanges()
	])