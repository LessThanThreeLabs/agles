window.RepositoryHeaderMenu = {}


class RepositoryHeaderMenu.Model extends Backbone.Model
	MENU_OPTIONS:
		'source': new RepositoryHeaderMenuOption 'source', 'Source Code', '/img/icons/sourceCode.svg'
		'builds': new RepositoryHeaderMenuOption 'builds', 'Builds', '/img/icons/builds.svg'
		'settings': new RepositoryHeaderMenuOption 'settings', 'Settings', '/img/icons/settings.svg'
		'admin': new RepositoryHeaderMenuOption 'admin', 'Admin', '/img/icons/admin.svg'
	defaults:
		repositoryId: null
		menuOptions: []
		selectedMenuOptionName: null
		url: ''

	initialize: () =>
		@repositoryUrlTrinketModel = new RepositoryUrlTrinket.Model()
		@router = new Backbone.Router()

		@on 'change:repositoryId', () =>
			@_updateAllowMenuOptions()
		@on 'change:selectedMenuOptionName', () =>
			@router.navigate 'repository/' + @get('repositoryId') + '/' + @get('selectedMenuOptionName'), trigger: true
		@on 'change:url', () =>
			@repositoryUrlPanelModel.set 'url', @get 'url'


	validate: (attributes) =>
		if selectedMenuOptionName? and not MENU_OPTIONS[selectedMenuOptionName]?
			return new Error 'Invalid selected menu option name'
		return


	_updateAllowMenuOptions: () =>
		console.log 'repositoryHeaderMenu.coffee - should make a server call to determine menu options'
		
		result =
			menuOptions: ['source', 'builds', 'settings', 'admin']
			defaultOption: 'builds'
		assert.ok result.defaultOption in result.menuOptions

		allowedOptions = result.menuOptions.map (option) =>
			assert.ok @MENU_OPTIONS[option]?
			return @MENU_OPTIONS[option]

		@set 'menuOptions', allowedOptions
		@set 'selectedMenuOptionName', result.defaultOption


class RepositoryHeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderMenu'
	template: Handlebars.compile '<div class="repositoryHeaderMenuOptions">
			<div class="repositoryMenuTrinkets"></div>
			{{#each options}}
			<div class="repositoryMenuOption" optionName="{{name}}" title="{{tooltipText}}" >
				<img src="{{{imageSource}}}" class="repositoryMenuOptionImage" optionName="{{name}}" />
			</div>
			{{/each}}
		</div>'
	events:
		'click .repositoryMenuOption': '_handleClick'

	initialize: () =>
		@model.on 'change:menuOptions', @render
		@model.on 'change:selectedMenuOptionName', @_handleSelectedMenuOption


	render: () =>
		@$el.html @template options: @model.get 'menuOptions'

		repositoryUrlTrinketView = new RepositoryUrlTrinket.View model: @model.repositoryUrlTrinketModel
		@$el.find('.repositoryMenuTrinkets').append repositoryUrlTrinketView.render().el

		# Needed for when the selected menu option 
		# was changed before the dom was rendered.
		@_handleSelectedMenuOption()

		Tipped.create '.repositoryMenuOption', skin: 'default'

		return @


	_handleClick: (event) =>
		optionName = $(event.target).attr 'optionName'
		assert.ok optionName?
		@model.set 'selectedMenuOptionName', optionName


	_handleSelectedMenuOption: () =>
		@$el.find('.repositoryMenuOption').removeClass 'selected'

		optionName = @model.get 'selectedMenuOptionName'
		@$el.find(".repositoryMenuOption[optionName='#{optionName}']").addClass 'selected'
