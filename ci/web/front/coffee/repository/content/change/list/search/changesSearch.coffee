window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		queryString: ''


class BuildsSearch.View extends Backbone.View
	tagName: 'div'
	className: 'buildsSearch'
	html: '<input type="search" class="buildsSearchField" placeholder="search..." maxlength=256 autocomplete="on">'
	events:
		'keyup .buildsSearchField': '_handleKeyDown'
		'blur .buildsSearchField': '_handleKeyDown'


	initialize: () =>
		@model.on 'change:queryString', @_syncModelToView, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @html
		@_syncModelToView()
		return @


	_syncModelToView: () =>
		$('.buildsSearchField').val @model.get 'queryString'


	_handleKeyDown: (event) =>
		@model.set 'queryString', $('.buildsSearchField').val()
