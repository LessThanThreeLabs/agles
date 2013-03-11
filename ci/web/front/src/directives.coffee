'use strict'

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
	).
	directive('consoleText', ['ansiparse', (ansiparse) ->
		restrict: 'E'
		replace: true
		scope: lines: '=consoleTextLines'
		template: '<div class="prettyConsoleText"></div>'
		link: (scope, element, attributes) ->
			addLine = (number, line="", linePreviouslyExisted) ->
				ansiParsedLine = ansiparse.parse line
				html = "<span class='prettyConsoleTextLineNumber'>#{number}</span><span class='prettyConsoleTextLineText textSelectable'>#{ansiParsedLine}</span>"

				if linePreviouslyExisted
					element.find(".prettyConsoleTextLine:nth-child(#{number})").html html
				else
					element.append '<span class="prettyConsoleTextLine">' + html + '</span>'

			handleLinesUpdate = (newValue, oldValue) ->
				if not newValue? or newValue.length is 0
					element.empty()
				else
					for line, index in newValue
						if newValue[index] isnt oldValue[index] or index >= oldValue.length
							addLine index+1, line, oldValue[index]?

			scope.$watch 'lines', handleLinesUpdate, true
	])