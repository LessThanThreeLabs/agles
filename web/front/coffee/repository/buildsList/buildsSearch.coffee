window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		query: ''

	initialize: () =>
		


class BuildsSearch.View extends Backbone.View
	tagName: 'div'
	className: 'buildsSearch'
	template: Handlebars.compile '<span class="dropdown">
			<a class="dropdown-toggle" data-toggle="dropdown" href="#">
				<img src="/img/icons/critical.svg" class="searchImage" /><span class="caret"></span>
			</a>
			<ul class="dropdown-menu" role="menu">
				<li><a tabindex="-1" href="#"><img src="/img/icons/everyone.svg" class="searchImage" />&nbsp;&nbsp;Everyone</a></li>
				<li><a tabindex="-1" href="#"><img src="/img/icons/user.svg" class="searchImage" />&nbsp;&nbsp;User</a></li>
				<li><a tabindex="-1" href="#"><img src="/img/icons/critical.svg" class="searchImage" />&nbsp;&nbsp;Critical</a></li>
			</ul>
		</span>
		<input class="searchField" type="search" maxlength=100 placeholder="Search..." data-provide="typeahead">'

	events:
		'keyup .searchField': 'keyupHandler'

	initialize: () =>


	render: () =>
		@$el.html @template()

		setTimeout (()-> 
			$('.searchField').typeahead
				source: ['jpotter', 'jchu', 'bbland']
			), 100

		return @


	keyupHandler: () =>
		@model.set 'query', $('.searchField').val()
