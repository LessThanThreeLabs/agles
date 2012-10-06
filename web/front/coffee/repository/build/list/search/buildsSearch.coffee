window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		query: ''

	initialize: () =>
		@buildsSearchFilterModel = new BuildsSearchFilter.Model()
		@buildsSearchFilterModel.on 'selectedFilterType', (filterType) =>
			@trigger 'selectedFilterType', filterType


class BuildsSearch.View extends Backbone.View
	tagName: 'div'
	className: 'buildsSearch'
	template: Handlebars.compile '<form class="form-search">
			<div class="input-prepend search">
				<input class="searchField search-query input-small" type="text" placeholder="Search...">
			</div>
		</form>'

	initialize: () =>
		@buildsSearchFilterView = new BuildsSearchFilter.View model: @model.buildsSearchFilterModel


	render: () =>
		@$el.html @template()
		@$el.find('.input-prepend').prepend @buildsSearchFilterView.render().el
		setTimeout (() => @_setupTypeAhead()), 100
		return @


	_setupTypeAhead: () =>
		$('.searchField').typeahead
			source: (query, process) ->
				console.log 'source called'
				return ['jpotter', 'jchu', 'bbland']
			updater: (item) ->
				console.log 'updater called'
				return item
