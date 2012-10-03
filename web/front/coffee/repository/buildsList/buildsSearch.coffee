window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		query: ''

	initialize: () =>
		


class BuildsSearch.View extends Backbone.View
	tagName: 'div'
	className: 'buildsSearch'
	template: Handlebars.compile '<img src="/img/search.svg" class="searchImage" /><input 
		class="searchField" type="search" maxlength=100 placeholder="Search...">'
	events:
		'keyup .searchField': 'keyupHandler'

	initialize: () =>


	render: () =>
		@$el.html @template()
		return @


	keyupHandler: () =>
		@model.set 'query', $('.searchField').val()
