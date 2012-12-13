window.PrettyDropdown = {}


class PrettyDropdown.Model extends Backbone.Model
	defaults:
		options: []
		visible: false
		alignment: 'left'


	toggleVisibility: () =>
		@set 'visible', not @get 'visible'


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
				<div class="prettyDropdownOption" optionName="{{name}}">{{title}}</div>
			{{/each}}'
	events: 'click .prettyDropdownOption': '_clickHandler'


	initialize: () =>
		@model.on 'change:options change:alignment', @render, @
		@model.on 'change:visible', @_fixVisibility, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template options: @model.get 'options'
		@_fixVisibility()
		@_fixAlignment()
		return @


	_fixVisibility: () =>
		@_fixGlobalClickListener()
		@$el.toggle @model.get 'visible'


	_fixGlobalClickListener: () =>
		if @model.get 'visible' then @_addGlobalClickListener()
		else @_removeGlobalClickListener()


	_addGlobalClickListener: () =>
		setTimeout (() => $('html').bind 'click', @_handleGlobalClick), 0


	_removeGlobalClickListener: () =>
		$('html').unbind 'click', @_handleGlobalClick


	_handleGlobalClick: (event) =>
		@_removeGlobalClickListener()
		@model.set 'visible', false


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
		event.stopPropagation()
