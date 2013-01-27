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

		it 'should handle showing correctly', () ->
			expect(element.css 'display').toBe 'none'

			scope.$apply () -> scope.dropdownShow = true
			expect(element.css 'display').not.toBe 'none'

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
			
			optionClicked = null
			scope.handleClick = (dropdownOptionName) ->
				optionClicked = dropdownOptionName

			spyOn(scope, 'handleClick').andCallThrough()

			options = element.find('.prettyDropdownOption')

			options.eq(0).click()
			expect(scope.handleClick).toHaveBeenCalledWith 'first'
			expect(scope.handleClick.calls.length).toBe 1

			options.eq(1).click()
			expect(scope.handleClick).toHaveBeenCalledWith 'second'
			expect(scope.handleClick.calls.length).toBe 2

			options.eq(1).click()
			expect(scope.handleClick.calls.length).toBe 3
