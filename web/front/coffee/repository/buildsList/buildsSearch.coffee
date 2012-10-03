window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		query: ''

	initialize: () =>
		


class BuildsSearch.View extends Backbone.View
	tagName: 'div'
	className: 'buildsSearch'
	template: Handlebars.compile '<img src="/img/icons/search.svg" class="searchImage" /><input 
		class="searchField" type="search" maxlength=100 placeholder="Search...">
		<input type="checkbox" name="filter" value="everyone"><img src="/img/icons/everyone.svg" class="everyoneImage" />
		<input type="checkbox" name="filter" value="user"><img src="/img/icons/user.svg" class="userImage" />
		<input type="checkbox" name="filter" value="critical"><img src="/img/icons/critical.svg" class="criticalImage" />'
	events:
		'keyup .searchField': 'keyupHandler'

	initialize: () =>


	render: () =>
		@$el.html @template()
		return @


	keyupHandler: () =>
		@model.set 'query', $('.searchField').val()
