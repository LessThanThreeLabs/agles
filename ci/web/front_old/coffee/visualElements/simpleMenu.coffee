window.SimpleMenu = {}


class SimpleMenu.Model extends Backbone.Model
	defaults:
		options: null
		selectedOptionName: null


	initialize: () =>
		assert.ok @get('options').some (option) =>
			return option.name is @get 'selectedOptionName'


class SimpleMenu.View extends Backbone.View
	tagName: 'div'
	className: 'simpleMenu'
	template: Handlebars.compile '<div class="menuOptions">
			{{#each options}}
				<div class="menuOption" optionName="{{name}}">{{title}}</div>
			{{/each}}
		</div>'
	events: 'click .menuOption': "_handleOptionClick"


	initialize: () ->
		@model.on 'change:options', @render, @
		@model.on 'change:selectedOptionName', @_handleSelectedOptionChange, @


	onDispose: () =>
		@model.off null, null, @


	render: () ->
		@$el.html @template options: @model.get 'options'
		@_handleSelectedOptionChange()
		return @


	_handleOptionClick: (event) =>
		optionName = $(event.target).attr 'optionName'
		assert.ok optionName? and optionName.length isnt ''

		@model.set 'selectedOptionName', optionName


	_handleSelectedOptionChange: () =>
		@$('.menuOption').removeClass 'selected'

		optionName = @model.get 'selectedOptionName'
		@$(".menuOption[optionName='#{optionName}']").addClass 'selected'
