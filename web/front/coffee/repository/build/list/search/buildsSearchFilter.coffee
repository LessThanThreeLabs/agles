window.BuildsSearchFilter = {}


class BuildsSearchFilter.Model extends Backbone.Model
	defaults:
		query: ''

	initialize: () =>
		@buildsSearchFilterSelectorModel = new BuildsSearchFilterSelector.Model()
		@buildsSearchFilterSelectorModel.on 'change:selectedType', (model, selectedType) =>
			@trigger 'selectedType', selectedType


class BuildsSearchFilter.View extends Backbone.View
	tagName: 'div'
	className: 'btn filterButton'
	template: Handlebars.compile '<img src="/img/icons/critical.svg" class="selectedSearchImage" />'

	initialize: () =>
		@buildsSearchFilterSelectorView = new BuildsSearchFilterSelector.View model: @model.buildsSearchFilterSelectorModel
		@model.on 'selectedType', @_handleFilterTypeSelection


	render: () =>
		@$el.html @template()
		@_setupPopover()
		return @


	_setupPopover: () =>
		@$el.popover
			title: 'Filter by Type'
			content: @buildsSearchFilterSelectorView.render().el


	_handleFilterTypeSelection: (selectedType) =>
		$('.selectedSearchImage').attr 'src', selectedType.imageSource
			