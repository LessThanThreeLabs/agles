window.PrettyDropdown = {}


class PrettyDropdown.Model extends Backbone.Model
	defaults:
		options: []
		visible: true
		alignment: 'left'


	validate: (attributes) =>
		for option in attributes.options
			if not option.name? or not option.title?
				return new Error 'Invalid dropdown option'

		if attributes.alignment isnt 'left' and attributes.alignment isnt 'right'
			return new Error 'Invalid alignment'

		return


class PrettyDropdown.View extends Backbone.View
	tagName: 'div'
	className: 'prettyDropdown'
	template: Handlebars.compile '{{#each options}}
				<div class="dropdownOption" optionName="{{name}}">{{title}}</div>
			{{/each}}'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'change', @render, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template options: @model.get 'options'
		@_fixVisibility()
		@_fixAlignment()
		return @


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'


	_fixAlignment: () =>
		@$el.removeClass 'leftAligned rightAligned'

		switch @model.get 'alignment'
			when 'left'
				@$el.addClass 'leftAligned'
			when 'right'
				@$el.addClass 'rightAligned'
			else
				console.error 'Unaccounted for dropdown alignment'


	_clickHandler: (event) =>
		console.log 'need to handle repository click!'
		