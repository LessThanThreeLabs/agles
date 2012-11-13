window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		queryString: ''

	initialize: () =>


class BuildsSearch.View extends Backbone.View
	tagName: 'div'
	className: 'buildsSearch'
	template: Handlebars.compile '<input type="search" class="buildsSearchField" placeholder="search..." maxlength=256 autocomplete="on">'
	events:
		'keyup .buildsSearchField': '_handleKeyDown'

	initialize: () =>

	render: () =>
		@$el.html @template()
		$('.buildsSearchField').val @model.get 'queryString'
		return @


	_handleKeyDown: (event) =>
		@model.set 'queryString', $('.buildsSearchField').val()
