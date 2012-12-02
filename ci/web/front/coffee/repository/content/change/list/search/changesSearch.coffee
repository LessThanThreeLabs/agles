window.ChangesSearch = {}


class ChangesSearch.Model extends Backbone.Model
	defaults:
		queryString: ''


class ChangesSearch.View extends Backbone.View
	tagName: 'div'
	className: 'changesSearch'
	html: '<input type="search" class="changesSearchField" placeholder="search..." maxlength=256 autocomplete="on">'
	events:
		'keyup .changesSearchField': '_handleKeyDown'
		'blur .changesSearchField': '_handleKeyDown'


	initialize: () =>
		@model.on 'change:queryString', @_syncModelToView, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @html
		@_syncModelToView()
		return @


	_syncModelToView: () =>
		$('.changesSearchField').val @model.get 'queryString'


	_handleKeyDown: (event) =>
		@model.set 'queryString', $('.changesSearchField').val()
