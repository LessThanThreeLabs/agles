window.RepositoryHeaderMenu = {}


class RepositoryHeaderMenu.Model extends Backbone.Model
	MENU_OPTIONS:
		'source': new RepositoryHeaderMenuOption 'source', 'Source Code', '/img/icons/sourceCode.svg'
		'builds': new RepositoryHeaderMenuOption 'builds', 'Builds', '/img/icons/builds.svg'
		'settings': new RepositoryHeaderMenuOption 'settings', 'Settings', '/img/icons/settings.svg'
		'admin': new RepositoryHeaderMenuOption 'admin', 'Admin', '/img/icons/admin.svg'
	default:
		repositoryId: null
		menuOptions: []
		selectedMenuOptionName: null

	initialize: () =>
		@on 'change:repositoryId', @_updateAllowMenuOptions


	validate: (attributes) =>
		if not attributes.repositoryId?
			return new Error 'Invalid repository id'
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
			<div class="blankRepositoryMenuOption"></div>
			{{#each options}}
			<div class="repositoryMenuOption" optionName={{name}}>
				<img src={{{imageSource}}} class="repositoryMenuOptionImage" optionName={{name}} />
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

		# Needed for when the selected menu option 
		# was changed before the dom was rendered.
		@_handleSelectedMenuOption()

		return @


	_handleClick: (event) =>
		optionName = $(event.target).attr 'optionName'
		assert.ok optionName?
		@model.set 'selectedMenuOptionName', optionName


	_handleSelectedMenuOption: () =>
		@$el.find('.repositoryMenuOption').removeClass 'selected'

		optionName = @model.get 'selectedMenuOptionName'
		@$el.find(".repositoryMenuOption[optionName='#{optionName}']").addClass 'selected'
