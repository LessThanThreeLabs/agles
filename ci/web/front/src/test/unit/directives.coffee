'use strict'

describe 'Koality directives', () ->

	describe 'dropdown directive', () ->
		element = null
		scope = null

		beforeEach module 'koality.directive'

		beforeEach () ->
			inject ($rootScope, $compile) ->
				scope = $rootScope.$new()
				element = angular.element '<dropdown alignment="left" dropdown-options="dropdownOptions" dropdown-show="dropdownShow" dropdown-option-click="handleClick(dropdownOption)" />'
				$compile(element)(scope)
				scope.$digest()

		it 'should render the correct number of options', () ->
			createOption = (optionNum) ->
				title: optionNum
				name: optionNum

			numOptions = 5
			scope.$apply () -> scope.dropdownOptions = (createOption optionNum for optionNum in [0...numOptions])
			options = element.find('.prettyDropdownOption')
			expect(options.length).toBe numOptions

			numOptions = 7
			scope.$apply () -> scope.dropdownOptions = (createOption optionNum for optionNum in [0...numOptions])
			options = element.find('.prettyDropdownOption')
			expect(options.length).toBe numOptions

		it 'should handle option click properly', () ->
			scope.$apply () -> scope.dropdownOptions = [{title: 'First', name: 'first'}, {title: 'Second', name: 'second'}]
			
			scope.handleClick = (dropdownOptionName) ->
			spyOn(scope, 'handleClick')

			options = element.find '.prettyDropdownOption'

			options.eq(0).click()
			expect(scope.handleClick).toHaveBeenCalledWith 'first'
			expect(scope.handleClick.calls.length).toBe 1

			options.eq(1).click()
			expect(scope.handleClick).toHaveBeenCalledWith 'second'
			expect(scope.handleClick.calls.length).toBe 2

			options.eq(1).click()
			expect(scope.handleClick.calls.length).toBe 3

	describe 'menu directive', () ->
		element = null
		scope = null

		beforeEach module 'koality.directive'

		beforeEach () ->
			inject ($rootScope, $compile) ->
				scope = $rootScope.$new()
				element = angular.element '<menu menu-options="[\'optionA\', \'optionB\', \'optionC\', \'optionD\']" default-menu-option="optionB" menu-option-click="handleClick(option)">
						<div class="prettyMenuContent" option="optionA">blahA</div>
						<div class="prettyMenuContent" option="optionB">blahB</div>
						<div class="prettyMenuContent" option="optionC">blahC</div>
						<div class="prettyMenuContent" option="optionD">blahD</div>
					</menu>'
				$compile(element)(scope)
				scope.$digest()

		it 'should render the correct number of options', () ->
			options = element.find '.prettyMenuOption'
			expect(options.length).toBe 4

		it 'should handle option click properly', () ->
			scope.handleClick = (dropdownOptionName) ->
			spyOn(scope, 'handleClick')

			options = element.find '.prettyMenuOption'

			options.eq(0).click()
			expect(scope.handleClick).toHaveBeenCalledWith 'optionA'
			expect(scope.handleClick.calls.length).toBe 1

			options.eq(2).click()
			expect(scope.handleClick).toHaveBeenCalledWith 'optionC'
			expect(scope.handleClick.calls.length).toBe 2

			options.eq(0).click()
			expect(scope.handleClick.calls.length).toBe 3
