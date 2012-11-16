window.RepositoryAdminMenu = {}


class RepositoryAdminMenu.Model extends Backbone.Model
	defaults:
		options: ['first option', 'second option', 'third option', 'fourth option']
		selectedOption: 'first option'

	initialize: () ->


class RepositoryAdminMenu.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMenu'
	template: Handlebars.compile '<div class="menuOptions">
			{{#each options}}
				<div class="menuOption" optionName="{{this}}">{{this}}</div>
			{{/each}}
		</div>'
	events:
		'click .menuOption': "_handleOptionClick"

	initialize: () ->
		@model.on 'change:options', @render
		@model.on 'change:selectedOption', @_handleSelectedOptionChange


	render: () ->
		@$el.html @template options: @model.get 'options'
		@_handleSelectedOptionChange()
		return @


	_handleOptionClick: (event) =>
		optionName = $(event.target).attr 'optionName'
		assert.ok optionName? and optionName.length isnt ''

		@model.set 'selectedOption', optionName


	_handleSelectedOptionChange: () =>
		@$el.find('.menuOption').removeClass 'selected'

		optionName = @model.get 'selectedOption'
		@$el.find(".menuOption[optionName='#{optionName}']").addClass 'selected'
