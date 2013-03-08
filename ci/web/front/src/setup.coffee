'use strict'

angular.module('koality.service', []).
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
			partyMode: false
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

		makeRequest: (resource, requestType, methodName, data, callback) ->
			assert.ok typeof resource is 'string' and typeof requestType is 'string' and typeof methodName is 'string'
			assert.ok resource.indexOf('.') is -1 and requestType.indexOf('.') is -1
			socket.emit "#{resource}.#{requestType}", {method: methodName, args: data}, (error, response) ->
				if error?
					console.log "#{resource}.#{requestType} - #{methodName}"
					console.error error
				switch error
					when 400, 404, 500 then window.location.href = '/unexpectedError'
					when 403 then window.location.href = '/invalidPermissions'
					else callback error, response if callback?

		respondTo: (eventName, callback) ->
			socket.on eventName, callback
	]).
	factory('rpc', ['socket', (socket) ->
		makeRequest: socket.makeRequest
	]).
	factory('events', ['socket', 'integerConverter', (socket, integerConverter) ->
		listen: (resource, eventName, id) ->
			_callback: null
			id = integerConverter.toInteger id

			setCallback: (callback) ->
				assert.ok callback?
				@_callback = callback
				return @

			subscribe: () ->
				socket.makeRequest resource, 'subscribe', eventName, id: id, (error, eventToListenFor) =>
					if error? then console.error error
					else socket.respondTo eventToListenFor, (data) =>
						@_callback data if @_callback?
				return @

			unsubscribe: () ->
				socket.makeRequest resource, 'unsubscribe', eventName, id: id, (error) ->
					console.error if error?
				return @
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
	]).
	factory('crazyAnsiText', ['initialState', (initialState) ->
		return makeCrazy: (text) ->
			return text if not initialState.partyMode

			prefix = '\x1b[' + (Math.round(Math.random() * 9) + 30) + ';' + (Math.round(Math.random() * 9) + 40) + 'm'
			return prefix + text
	])


angular.module('koality.directive', []).
	directive('unselectable', () ->
		return (scope, element, attributes) ->
			element.addClass 'unselectable'
	).
	directive('textSelectable', () ->
		return (scope, element, attributes) ->
			element.addClass 'textSelectable'
	).
	directive('highlightOnFirstClick', () ->
		return (scope, element, attributes) ->
			highlightText = () ->
				element.select()
				element.unbind 'click', highlightText

			element.bind 'click', highlightText
	).
	directive('focused', () ->
		return (scope, element, attributes) ->
			element.focus()
	).
	directive('inputFocusOnClick', () ->
		return (scope, element, attributes) ->
			element.bind 'click', (event) ->
				element.find('input').focus()
	).
	directive('centeredPanel', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyCenteredPanel" ng-transclude></div>'
	).
	directive('dropdown', ['$document', '$timeout', ($document, $timeout) ->
		restrict: 'E'
		replace: true
		scope:
			alignment: '@alignment'
			options: '=dropdownOptions'
			clickHandler: '&dropdownOptionClick'
		template: '<div class="prettyDropdown {{alignment}}Aligned" ng-show="show">
			<div class="prettyDropdownOption" ng-repeat="option in options" ng-click="clickHandler({dropdownOption: option.name})">{{option.title}}</div>
			</div>'
		link: (scope, element, attributes) ->
			element.parent().bind 'click', () ->
				scope.$apply () -> scope.show = !scope.show

			documentClickHandler = (event) ->
				scope.$apply () -> scope.show = false

			scope.$watch 'show', () ->
				if scope.show then $timeout (() -> $document.bind 'click', documentClickHandler), 0
				else $document.unbind 'click', documentClickHandler

			element.bind 'click', (event) ->
				scope.$apply () -> scope.show = false
				event.preventDefault()
				event.stopPropagation()
	]).
	directive('autoScrollToBottom', ['integerConverter', (integerConverter) ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			scrollBottomBuffer = integerConverter.toInteger(attributes.autoScrollToBottomBuffer) ? 20
			scope.$watch attributes.autoScrollToBottom, (() ->
				isScrolledToBottomIsh = element[0].scrollTop + element[0].offsetHeight + scrollBottomBuffer >= element[0].scrollHeight
				element[0].scrollTop = element[0].scrollHeight if isScrolledToBottomIsh
				), true
	]).
	directive('modal', ['$document', ($document) ->
		restrict: 'E'
		replace: true
		transclude: true
		scope: show: '=modalVisible'
		template: '<div class="prettyModal" ng-class="{visible: show}">
				<div class="prettyModalBackdrop" ng-click="show=false"></div>
				<div class="prettyModalContent" ng-transclude></div>
			</div>'
		link: (scope, element, attributes) ->
			escapeClickHandler = (event) ->
				if event.keyCode is 27
					scope.$apply () -> scope.show = false

			scope.$watch 'show', () ->
				if scope.show
					$document.bind 'keydown', escapeClickHandler
					setTimeout (() ->
						firstInput = element.find('input,textarea,select').get(0)
						firstInput.focus() if firstInput?
					), 0
				else
					$document.unbind 'keydown', escapeClickHandler
	]).
	directive('tooltip', () ->
		restrict: 'A'
		replace: true
		transclude: true
		scope: true
		template: '<span class="prettyTooltipContainer" ng-transclude>
				<span class="prettyTooltipCenterAnchor">
					<span class="prettyTooltipCenterContainer">
						<span class="prettyTooltip">{{text}}</span>
					</span>
				</span>
			</span>'
		compile: (element, attributes, transclude) ->
			pre: (scope, element, attributes, controller) ->
				scope.text = attributes.tooltip
	).
	directive('styledForm', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<form class="prettyForm" novalidate ng-transclude>
			</form>'
		link: (scope, element, attributes) ->
			if attributes.styledFormAlignment is 'center'
				element.addClass 'center'
	).
	directive('styledFormField', () ->
		restrict: 'E'
		replace: true
		transclude: true
		scope:
			label: '@label'
			padding: '@labelPadding'
		template: '<div class="prettyFormRow">
				<div class="prettyFormLabel" ng-class="{labelPadding: padding}">{{label}}</div>
				<div class="prettyFormValue" ng-transclude>
				</div>
			</div>'
	).
	directive('contentMenu', () ->
		restrict: 'E'
		require: 'ngModel'
		replace: true
		transclude: true
		template: '<div class="prettyContentMenu" unselectable ng-transclude>
				<div class="prettyContentMenuBackgroundPanel"></div>
				<div class="prettyContentMenuFooter"></div>
			</div>'
	).
	directive('contentMenuHeader', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyContentMenuHeader" ng-transclude>
				<div class="prettyContentMenuHeaderBuffer"></div>
			</div>'
		link: (scope, element, attributes) ->
			if attributes.menuHeaderPadding?
				element.addClass 'prettyContentMenuHeaderPadding'
	).
	directive('contentMenuOptions', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyContentMenuOptions">
				<div class="prettyContentMenuOptionsScrollOuterWrapper">
					<div class="prettyContentMenuOptionsScrollInnerWrapper" ng-transclude></div>
				</div>
			</div>'
		link: (scope, element, attributes) ->
			addScrollListener = () ->
				outerElement = element.find('.prettyContentMenuOptionsScrollOuterWrapper')
				outerElement.bind 'scroll', (event) ->
					scrolledToBottom = outerElement[0].scrollTop + outerElement[0].offsetHeight >= outerElement[0].scrollHeight
					scope.$apply attributes.onScrollToBottom if scrolledToBottom

			addScrollListener() if attributes.onScrollToBottom?
	).
	directive('contentMenuOption', () ->
		restrict: 'E'
		replace: true
		scope: true
		template: '<div class="prettyContentMenuOption">
				<div class="prettyContentMenuOptionContents">
					<span class="prettyContentMenuOptionIdentifier">{{identifier}}</span>
					<span class="prettyContentMenuOptionText">{{text}}</span>
					<div class="prettyContentMenuOptionArrow"></div>
					<spinner class="prettyContentMenuOptionSpinner" spinner-running="spinning"></spinner>
				</div>
				<div class="prettyContentMenuOptionTooth"></div>
			</div>'
		link: (scope, element, attributes) ->
			checkOffsetTextClass = () ->
				if scope.identifier? and scope.text? then element.find('.prettyContentMenuOptionContents').addClass 'offsetText'
				else element.find('.prettyContentMenuOptionContents').removeClass 'offsetText'

			attributes.$observe 'menuOptionIdentifier', (identifier) ->
				scope.identifier = identifier
				checkOffsetTextClass()

			attributes.$observe 'menuOptionText', (text) ->
				scope.text = text
				checkOffsetTextClass()

			attributes.$observe 'menuOptionSpinning', (spinning) ->
				scope.spinning = if typeof spinning is 'boolean' then spinning else spinning is 'true'
	).
	directive('content', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyContent" ng-transclude>
				<div class="prettyContentFooter"></div>
			</div>'
	).
	directive('contentHeader', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyContentHeader" unselectable ng-transclude></div>'
		link: (scope, element, attributes) ->
			if attributes.contentHeaderPadding?
				element.addClass 'prettyContentHeaderPadding'
	).
	directive('contentBody', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyContentBody" ng-transclude></div>'
	).
	directive('spinner', () ->
		restrict: 'E'
		replace: true
		scope: running: '=spinnerRunning'
		template: '<div class="spinnerContainer"></div>'
		link: (scope, element, attributes) ->
			spinner = null

			spinnerOptions =
				lines: 7
				length: 3
				width: 3
				radius: 5
				corners: 1
				rotate: 14
				color: '#FFFFFF'
				speed: 1.2
				trail: 30
				shadow: false
				hwaccel: true
				className: 'spinner'
				zIndex: 2e9
				top: 'auto'
				left: 'auto'

			scope.$watch 'running', (newValue, oldValue) ->
				if newValue then startSpinner() else stopSpinner()

			startSpinner = () ->
				spinner = new Spinner(spinnerOptions).spin(element[0])

			stopSpinner = () ->
				spinner.stop() if spinner?
	)


angular.module('koality.filter', ['koality.service']).
	filter('ansiparse', ['$window', ($window) ->
		(input) ->
			return '<span class="ansi">' + $window.ansiparse(input) + '</span>'
	]).
	filter('fileSuffix', ['fileSuffixAdder', (fileSuffixAdder) ->
		(input) ->
			return fileSuffixAdder.addFileSuffix input
	]).
	filter('newLine', [() ->
		(input) ->
			return null if not input? or typeof input isnt 'string'
			return input.replace '\n', '<br>'
	])


angular.module('koality', ['ngSanitize', 'koality.service', 'koality.directive', 'koality.filter']).
	config(['$routeProvider', ($routeProvider) ->
		$routeProvider.
			when('/welcome',
				templateUrl: "/html/welcome#{fileSuffix}.html"
				controller: Welcome
				redirectTo: if window.accountInformation.id is '' then '/login' else null
			).
			when('/login',
				templateUrl: "/html/login#{fileSuffix}.html"
				controller: Login
				redirectTo: if window.accountInformation.id is '' then null else '/'
			).
			when('/account',
				templateUrl: "/html/account#{fileSuffix}.html"
				controller: Account
				reloadOnSearch: false
				redirectTo: if window.accountInformation.id is '' then '/login' else null
			).
			when('/create/account',
				templateUrl: "/html/createAccount#{fileSuffix}.html"
				controller: CreateAccount
				reloadOnSearch: false
				redirectTo: if window.accountInformation.id is '' then null else '/'
			).
			when('/resetPassword',
				templateUrl: "/html/resetPassword#{fileSuffix}.html"
				controller: ResetPassword
				redirectTo: if window.accountInformation.id is '' then null else '/'
			).
			when('/repository/:repositoryId',
				templateUrl: "/html/repository#{fileSuffix}.html"
				controller: Repository
				reloadOnSearch: false
				redirectTo: if window.accountInformation.id is '' then '/login' else null
			).
			when('/admin',
				templateUrl: "/html/admin#{fileSuffix}.html"
				controller: Admin
				reloadOnSearch: false
				redirectTo: if window.accountInformation.isAdmin then null else '/'
			).
			when('/unexpectedError',
				templateUrl: "/html/unexpectedError#{fileSuffix}.html"
				controller: UnexpectedError
			).
			when('/invalidPermissions',
				templateUrl: "/html/invalidPermissions#{fileSuffix}.html"
				controller: InvalidPermissions
			).
			otherwise(
				redirectTo: '/welcome'
			)
	]).
	config(['$locationProvider', ($locationProvider) ->
		$locationProvider.html5Mode true
	]).
	run(() ->
		# initialization happens here
	)
