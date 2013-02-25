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
	factory('socket', ['$location', 'initialState', ($location, initialState) ->
		socket = io.connect "//#{$location.host()}?csrfToken=#{initialState.csrfToken}", resource: 'socket'
		
		makeRequest: (resource, requestType, methodName, data, callback) ->
			assert.ok typeof resource is 'string' and typeof requestType is 'string' and typeof methodName is 'string'
			assert.ok resource.indexOf('.') is -1 and requestType.indexOf('.') is -1
			socket.emit "#{resource}.#{requestType}", {method: methodName, args: data}, (error, response) ->
				switch error
					when 400, 404, 500 then $location.path('/unexpectedError').search {}
					when 403 then $location.path('/invalidPermissions').search {}
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
	factory('changesRpc', ['rpc', (rpc) ->
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
	directive('listenForEnterKey', () ->
		return (scope, element, attributes) ->
			element.bind 'keypress', (event) ->
				if event.keyCode is 13
					ignoreEnter = scope.$eval attributes.ignoreEnterKeyIf
					scope.$apply attributes.listenForEnterKey if not ignoreEnter
	).
	directive('focused', () ->
		return (scope, element, attributes) ->
			element.focus()
	).
	directive('scrollbarWrapper', () ->
		restrict: 'A'
		replace: true
		transclude: true
		template: '<div class="hideScrollbarOuter">
				<div class="hideScrollbarInner">
					<div class="hideScrollbarContent" ng-transclude></div>
				</div>
			</div>'
		link: (scope, element, attributes) ->
			setWidths = () ->
				element.css 'overflow', 'hidden'

				element.find('.hideScrollbarInner').width element.width() + 25
				element.find('.hideScrollbarInner').height element.height()
				element.find('.hideScrollbarInner').css 'overflow-y', 'auto'

				element.find('.hideScrollbarContent').width element.width()

			listenForBottomScroll = () ->
				return if not attributes.scrollbarWrapperNotifyOnBottomScroll?

				innerElement = element.find('.hideScrollbarInner')
				innerElement.bind 'scroll', () ->
					if innerElement[0].scrollTop + innerElement[0].offsetHeight >= innerElement[0].scrollHeight
						scope.$apply attributes.scrollbarWrapperNotifyOnBottomScroll

			setWidths()
			listenForBottomScroll()
	).
	directive('centeredPanel', () ->
		restrict: 'E'
		replace: true
		transclude: true
		scope: title: '@panelTitle'
		template: '<div class="prettyPanelContainer">
				<div class="prettyPanel" unselectable>
					<div class="prettyPanelTitle" ng-show="title">{{title}}</div>
					<div ng-transclude></div>
				</div>
			</div>'
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
	# directive('menu', () ->
	# 	restrict: 'E'
	# 	replace: true
	# 	transclude: true
	# 	scope: 
	# 		options: '=options'
	# 		currentOptionName: '=currentOptionName'
	# 		clickHandler: '&optionClick'
	# 	template: '<div class="prettyMenu">
	# 			<div class="prettyMenuOptions">
	# 				<div class="prettyMenuOption" ng-repeat="option in options" ng-class="{selected: option.name == currentOptionName}" ng-click="clickHandler({optionName: option.name}); internalClickHandler(option)">{{option.title}}</div>
	# 			</div>
	# 			<div class="prettyMenuContents" ng-transclude></div>
	# 		</div>'
	# 	link: (scope, element, attributes) ->
	# 		scope.$watch 'currentOptionName', () ->
	# 			element.find('.prettyMenuContent').removeClass 'selected'
	# 			element.find(".prettyMenuContent[optionName='#{scope.currentOptionName}']").addClass 'selected'

	# 		scope.internalClickHandler = (option) ->
	# 			scope.currentOptionName = option.name

	# ).
	directive('autoScrollToBottom', () ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			scrollBottomBuffer = 20
			scope.$watch attributes.autoScrollToBottom, (() ->
				isScrolledToBottomIsh = element[0].scrollTop + element[0].offsetHeight + scrollBottomBuffer >= element[0].scrollHeight
				element[0].scrollTop = element[0].scrollHeight if isScrolledToBottomIsh
				), true
	).
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
				if scope.show then $document.bind 'keydown', escapeClickHandler
				else $document.unbind 'keydown', escapeClickHandler
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
	directive('menu', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyMenu" ng-transclude>
				<div class="prettyMenuFooter"></div>
			</div>'
	).
	directive('menuHeader', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyMenuHeader" ng-transclude></div>'
	).
	directive('menuOptions', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyMenuOptions">
				<div class="prettyMenuOptionsScrollOuterWrapper">
					<div class="prettyMenuOptionsScrollInnerWrapper" ng-transclude></div>
				</div>
			</div>'
	).
	directive('menuOption', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="prettyMenuOption">
				<div class="prettyMenuOptionContents">
					<span class="prettyMenuOptionText">{{text}}</span>
					<span class="prettyMenuOptionSubtext">{{subtext}}</span>
					<div class="prettyMenuOptionArrow"></div>
				</div>
				<div class="prettyMenuOptionTooth"></div>
			</div>'
		link: (scope, element, attributes) ->
			attributes.$observe 'menuOptionText', (text) ->
				scope.text = text
			attributes.$observe 'menuOptionSubtext', (subtext) ->
				scope.subtext = subtext
	)


angular.module('koality.filter', ['koality.service']).
	filter('ansiparse', ['$window', ($window) ->
		(input) ->
			return '<span class="ansi">' + $window.ansiparse input + '</span>'
	]).
	filter('fileSuffix', ['fileSuffixAdder', (fileSuffixAdder) ->
		(input) ->
			return fileSuffixAdder.addFileSuffix input
	])


angular.module('koality', ['ngSanitize', 'koality.service', 'koality.directive', 'koality.filter']).
	config(['$routeProvider', ($routeProvider) ->
		$routeProvider.
			when('/welcome',
				templateUrl: "/html/welcome#{fileSuffix}.html"
				controller: Welcome
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
				redirectTo: if window.accountInformation.id is '' then '/' else null
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
				redirectTo: if window.accountInformation.id is '' then '/' else null
			).
			when('/add/repository',
				templateUrl: "/html/addRepository#{fileSuffix}.html"
				controller: AddRepository
				redirectTo: if window.accountInformation.isAdmin then null else '/'
			).
			when('/remove/repository',
				templateUrl: "/html/removeRepository#{fileSuffix}.html"
				controller: RemoveRepository
				redirectTo: if window.accountInformation.isAdmin then null else '/'
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
		console.log 'initialization happens here'
	)
