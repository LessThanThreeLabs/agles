window.RepositoryAdminMenu = {}


class RepositoryAdminMenu.Model extends Backbone.Model

	initialize: () ->
		assert.ok @get('options').some (option) =>
			return option.name is @get 'selectedOptionName'


class RepositoryAdminMenu.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMenu'
	template: Handlebars.compile '<div class="menuOptions">
			{{#each options}}
				<div class="menuOption" optionName="{{name}}">{{title}}</div>
			{{/each}}
		</div>'
	events:
		'click .menuOption': "_handleOptionClick"

	initialize: () ->
		@model.on 'change:options', @render
		@model.on 'change:selectedOptionName', @_handleSelectedOptionChange


	render: () ->
		@$el.html @template options: @model.get 'options'
		@_handleSelectedOptionChange()
		return @


	_handleOptionClick: (event) =>
		optionName = $(event.target).attr 'optionName'
		assert.ok optionName? and optionName.length isnt ''

		@model.set 'selectedOptionName', optionName


	_handleSelectedOptionChange: () =>
		@$el.find('.menuOption').removeClass 'selected'

		optionName = @model.get 'selectedOptionName'
		@$el.find(".menuOption[optionName='#{optionName}']").addClass 'selected'
