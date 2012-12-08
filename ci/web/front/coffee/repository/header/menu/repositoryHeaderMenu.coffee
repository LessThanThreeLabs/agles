window.RepositoryHeaderMenu = {}


class RepositoryHeaderMenu.Model extends Backbone.Model
	MENU_OPTIONS:
		'source': new RepositoryHeaderMenuOption 'source', 'Source Code', '/img/icons/sourceCode.svg'
		'changes': new RepositoryHeaderMenuOption 'changes', 'Changes', '/img/icons/changes.svg'
		'settings': new RepositoryHeaderMenuOption 'settings', 'Settings', '/img/icons/settings.svg'
		'admin': new RepositoryHeaderMenuOption 'admin', 'Admin', '/img/icons/admin.svg'
	defaults:
		menuOptions: []
		url: ''


	initialize: () =>
		@repositoryUrlTrinketModel = new RepositoryUrlTrinket.Model()
		@router = new Backbone.Router()

		@on 'change:url', () =>
			@repositoryUrlTrinketModel.set 'url', @get 'url'


	fetchAllowedMenuOptions: () =>
		@clear()

		return if not globalRouterModel.get('repositoryId')?

		requestData =
			method: 'getMenuOptions'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
		
		socket.emit 'repos:read', requestData, (error, menuOptions) =>
			if error?
				console.error error
				return

			assert.ok menuOptions.default in menuOptions.options

			allowedOptions = menuOptions.options.map (option) =>
				assert.ok @MENU_OPTIONS[option]?
				return @MENU_OPTIONS[option]

			@set 'menuOptions', allowedOptions,
				error: (model, error) => console.error error

			if not globalRouterModel.get('repositoryView')? 
				globalRouterModel.set 'repositoryView', menuOptions.default,
					error: (model, error) => console.error error


	validate: (attributes) =>
		if selectedMenuOptionName? and not MENU_OPTIONS[selectedMenuOptionName]?
			return new Error 'Invalid selected menu option name'
		return


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
	events: 'click .repositoryMenuOption': '_handleClick'


	initialize: () =>
		@repositoryUrlTrinketView = new RepositoryUrlTrinket.View model: @model.repositoryUrlTrinketModel

		@model.on 'change:menuOptions', @render, @

		globalRouterModel.on 'change:repositoryId', @model.fetchAllowedMenuOptions, @
		globalRouterModel.on 'change:repositoryView', @_handleSelectedMenuOption, @

		@model.fetchAllowedMenuOptions()


	onDispose: () =>
		@model.off null, null, @
		globalRouterModel.off null, null, @

		@repositoryUrlTrinketView.dispose()


	render: () =>
		@$el.html @template options: @model.get 'menuOptions'

		@$el.find('.repositoryMenuTrinkets').append @repositoryUrlTrinketView.render().el

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

		optionName = globalRouterModel.get 'repositoryView'
		@$el.find(".repositoryMenuOption[optionName='#{optionName}']").addClass 'selected'
