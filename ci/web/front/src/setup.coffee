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
			loggedIn: $window.accountInformation?.id?
			partyMode: false
		return Object.freeze toReturn
	]).
	factory('fileSuffixAdder', ['initialState', (initialState) ->
		return addFileSuffix: (fileSrc) ->
			lastPeriodIndex = fileSrc.lastIndexOf '.'
			return fileSrc if lastPeriodIndex is -1
			return fileSrc.substr(0, lastPeriodIndex) + initialState.fileSuffix + fileSrc.substr(lastPeriodIndex)
	]).
	factory('socket', ['$location', 'initialState', ($location, initialState) ->
		socket = io.connect "//#{$location.host()}?csrfToken=#{initialState.csrfToken}", resource: 'socket'
		
		makeRequest: (resource, requestType, methodName, data, callback) ->
			assert.ok typeof resource is 'string' and typeof requestType is 'string' and typeof methodName is 'string'
			assert.ok resource.indexOf('.') is -1 and requestType.indexOf('.') is -1
			socket.emit "#{resource}.#{requestType}", {method: methodName, args: data}, callback
			console.log "rpc >> socket request made for #{resource} - #{requestType}, #{methodName} with:"
			console.log data

		respondTo: (eventName, callback) ->
			console.log 'events >> going to listen for event: ' + eventName
			socket.on eventName, callback
	]).
	factory('rpc', ['socket', (socket) ->
		makeRequest: socket.makeRequest
	]).
	factory('events', ['socket', (socket) ->
		listen: (resource, eventName, id) ->
			_callback: null

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
				scope.show = !scope.show

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
	directive('menu', () ->
		restrict: 'E'
		replace: true
		transclude: true
		scope: 
			currentOptionName: '=currentOptionName'
			clickHandler: '&optionClick'
		template: '<div class="prettyMenu">
				<div class="prettyMenuOptions">
					<div class="prettyMenuOption" ng-repeat="option in options" ng-class="{selected: option.name == currentOptionName}" ng-click="clickHandler({optionName: option.name}); internalClickHandler(option)">{{option.title}}</div>
				</div>
				<div class="prettyMenuContents" ng-transclude></div>
			</div>'
		compile: (element, attributes, transclude) ->
			pre: (scope, element, attributes, controller) ->
				scope.options = scope.$eval attributes.options
			post: (scope, element, attributes, controller) ->
				scope.$watch 'currentOptionName', () ->
					element.find('.prettyMenuContent').removeClass 'selected'
					element.find(".prettyMenuContent[optionName='#{scope.currentOptionName}']").addClass 'selected'

				scope.internalClickHandler = (option) ->
					scope.currentOptionName = option.name

	).
	directive('notifyOnBottomScroll', () ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			element.bind 'scroll', () ->
				if element[0].scrollTop + element[0].offsetHeight >= element[0].scrollHeight
					scope.$apply attributes.notifyOnBottomScroll
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
		scope: label: '@label'
		template: '<div class="prettyFormRow">
				<div class="prettyFormLabel labelPadding">{{label}}</div>
				<div class="prettyFormValue" ng-transclude>
				</div>
			</div>'
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
			).
			when('/account',
				templateUrl: "/html/account#{fileSuffix}.html"
				controller: Account
				reloadOnSearch: false
			).
			when('/create/account',
				templateUrl: "/html/createAccount#{fileSuffix}.html"
				controller: CreateAccount
			).
			when('/recoverPassword',
				templateUrl: "/html/recoverPassword#{fileSuffix}.html"
				controller: RecoverPassword
			).
			when('/repository/:repositoryId',
				templateUrl: "/html/repository#{fileSuffix}.html"
				controller: Repository
				reloadOnSearch: false
			).
			when('/add/repository',
				templateUrl: "/html/addRepository#{fileSuffix}.html"
				controller: AddRepository
			).
			when('/about',
				templateUrl: "/html/about#{fileSuffix}.html"
				controller: About
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
