window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		queryString: ''


class BuildsSearch.View extends Backbone.View
	tagName: 'div'
	className: 'buildsSearch'
	template: Handlebars.compile '<input type="search" class="buildsSearchField" placeholder="search..." maxlength=256 autocomplete="on">'
	events:
		'blur .buildsSearchField': '_handleKeyDown'
		'keyup .buildsSearchField': '_handleKeyDown'


	initialize: () =>
		@model.on 'change:queryString', @_syncModelToView


	render: () =>
		@$el.html @template()
		@_syncModelToView()
		return @


	_syncModelToView: () =>
		$('.buildsSearchField').val @model.get 'queryString'


	_handleKeyDown: (event) =>
		@model.set 'queryString', $('.buildsSearchField').val()
