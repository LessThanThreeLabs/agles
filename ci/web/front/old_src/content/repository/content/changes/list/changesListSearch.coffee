window.ChangesListSearch = {}


class ChangesListSearch.Model extends Backbone.Model
	defaults:
		queryString: ''


class ChangesListSearch.View extends Backbone.View
	tagName: 'div'
	className: 'changesListSearch'
	html: '<input type="search" class="changesListSearchField" placeholder="search..." maxlength=256 autocomplete="on">'
	events:
		'keyup .changesListSearchField': '_handleKeyDown'
		'blur .changesListSearchField': '_handleKeyDown'
		'click .changesListSearchField': '_handleKeyDown'


	initialize: () =>
		@model.on 'change:queryString', @_syncModelToView, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @html
		@_syncModelToView()
		return @


	_syncModelToView: () =>
		@$('.changesListSearchField').val @model.get 'queryString'


	_handleKeyDown: (event) =>
		@model.set 'queryString', @$('.changesListSearchField').val()
