window.BuildsSearch = {}


class BuildsSearch.Model extends Backbone.Model
	defaults:
		queryString: ''

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
	events:
		'blur .searchField': '_handleKeyDown'
		'keydown .searchField': '_handleKeyDown'

	initialize: () =>
		@buildsSearchFilterView = new BuildsSearchFilter.View model: @model.buildsSearchFilterModel


	render: () =>
		@$el.html @template()
		@$el.find('.input-prepend').prepend @buildsSearchFilterView.render().el
		$('.searchField').val @model.get 'queryString'
		setTimeout (() => @_setupTypeAhead()), 100
		return @


	_setupTypeAhead: () =>
		$('.searchField').typeahead
			source: (query, process) =>
				return ['jpotter', 'jchu', 'bbland']
			updater: (item) =>
				@_updateModelWithSearchField()
				return item


	_handleKeyDown: (event) =>
		@_updateModelWithSearchField()


	_updateModelWithSearchField: () =>
		setTimeout (() => @model.set 'queryString', $('.searchField').val()), 0
