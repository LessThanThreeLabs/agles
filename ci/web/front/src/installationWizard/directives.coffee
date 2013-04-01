'use strict'

angular.module('koalitySetup.directive', []).
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
		template: '<div class="prettyCenteredPanel" ng-transclude></div>'
	).
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
	)