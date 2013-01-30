'use strict'

angular.module('koality.service', []).
	factory('initialState', ['$window', ($window) ->
		toReturn =
			fileSuffix: if $window.fileSuffix is '' then null else $window.fileSuffix
			csrfToken: if $window.csrfToken is '' then null else $window.csrfToken
			user:
				email: if $window.accountInformation?.email is '' then null else $window.accountInformation?.email
				firstName: if $window.accountInformation?.firstName is '' then null else $window.accountInformation?.firstName
				lastName: if $window.accountInformation?.lastName is '' then null else $window.accountInformation?.lastName
		return Object.freeze toReturn
	]).
	factory('accountInformation', ['initialState', (initialState) ->
		email: initialState.user.email
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName
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
			console.log "socket request made for #{resource} - #{requestType} - #{functionName} with:"
			console.log data

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
					<div class="prettyPanelTitle">{{title}}</div>
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
			selectedOption: '@defaultMenuOption'
			clickHandler: '&menuOptionClick'
		template: '<div class="prettyMenu">
				<div class="prettyMenuOptions">
					<div class="prettyMenuOption" ng-repeat="option in options" ng-class="{selected: option == selectedOption}" ng-click="clickHandler({option: option}); internalClickHandler(option)">{{option}}</div>
				</div>
				<div class="prettyMenuContents" ng-transclude></div>
			</div>'
		compile: (element, attributes, transclude) ->
			pre: (scope, element, attributes, controller) ->
				scope.options = scope.$eval attributes.menuOptions
			post: (scope, element, attributes, controller) ->
				scope.$watch 'selectedOption', () ->
					element.find('.prettyMenuContent').removeClass 'selected'
					element.find(".prettyMenuContent[option='#{scope.selectedOption}']").addClass 'selected'

				scope.internalClickHandler = (option) ->
					scope.selectedOption = option
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
		template: '<span class="prettyTooltipContainer" ng-transclude>
				<span class="prettyTooltipCenterContainer">
					<span class="prettyTooltip">{{text}}</span>
				</span>
			</span>'
		compile: (element, attributes, transclude) ->
			pre: (scope, element, attributes, controller) ->
				scope.text = attributes.tooltip
	)
		



angular.module('koality.filter', [])


angular.module('koality', ['koality.service', 'koality.directive', 'koality.filter']).
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
