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
				scope.currentOptionName = 'optionB'
				element = angular.element '<menu options="[{title: \'Option A\', name: \'optionA\'}, {title: \'Option B\', name: \'optionB\'}, {title: \'Option C\', name: \'optionC\'}]" current-option-name="currentOptionName" option-click="handleClick(optionName)">
						<div class="prettyMenuContent" option="optionA">blahA</div>
						<div class="prettyMenuContent" option="optionB">blahB</div>
						<div class="prettyMenuContent" option="optionC">blahC</div>
						<div class="prettyMenuContent" option="optionD">blahD</div>
					</menu>'
				$compile(element)(scope)
				scope.$digest()

		it 'should render the correct number of options', () ->
			options = element.find '.prettyMenuOption'
			expect(options.length).toBe 3

		it 'should have the current option name selected', () ->
			selectedOption = element.find '.prettyMenuOption.selected'
			expect(selectedOption.html()).toBe 'Option B'

		it 'should call handleClick() on option click with correct values', () ->
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

		it 'should select the correct option upon click', () ->
			options = element.find '.prettyMenuOption'

			options.eq(0).click()
			expect(scope.currentOptionName).toBe 'optionA'

			options.eq(2).click()
			expect(scope.currentOptionName).toBe 'optionC'

			options.eq(0).click()
			expect(scope.currentOptionName).toBe 'optionA'

			options.eq(1).click()
			expect(scope.currentOptionName).toBe 'optionB'


	describe 'modal directive', () ->
		element = null
		scope = null

		beforeEach module 'koality.directive'

		it 'should become invisible when background is clicked', () ->
			inject ($rootScope, $compile) ->
				scope = $rootScope.$new()
				scope.modalVisible = true
				element = angular.element '<modal modal-visible="modalVisible">blah</modal>'
				$compile(element)(scope)
				scope.$digest()

			expect(scope.modalVisible).toBe true
			element.find('.prettyModalBackdrop').click()
			expect(scope.modalVisible).toBe false

	describe 'tooltip directive', () ->
		element = null
		scope = null

		beforeEach module 'koality.directive'

		it 'should render the correct tooltip text when valid text is provided', () ->
			tooltipText = 'blah'

			inject ($rootScope, $compile) ->
				scope = $rootScope.$new()
				element = angular.element "<span tooltip='#{tooltipText}'>hello</span>"
				$compile(element)(scope)
				scope.$digest()

			expect(element.find('.prettyTooltip').html()).toBe tooltipText

		it 'should render no tooltip text when no valid text is provided', () ->
			inject ($rootScope, $compile) ->
				scope = $rootScope.$new()
				element = angular.element "<span tooltip>hello</span>"
				$compile(element)(scope)
				scope.$digest()

			expect(element.find('.prettyTooltip').html()).toBe ''
			