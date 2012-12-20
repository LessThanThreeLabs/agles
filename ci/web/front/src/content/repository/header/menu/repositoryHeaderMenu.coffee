window.RepositoryHeaderMenu = {}


class RepositoryHeaderMenu.Model extends Backbone.Model
	POSSIBLE_MENU_OPTIONS:
		'source': new RepositoryHeaderMenuOption 'source', 'Source Code', '/img/icons/sourceCode.svg'
		'changes': new RepositoryHeaderMenuOption 'changes', 'Changes', '/img/icons/changes.svg'
		'settings': new RepositoryHeaderMenuOption 'settings', 'Settings', '/img/icons/settings.svg'
		'admin': new RepositoryHeaderMenuOption 'admin', 'Admin', '/img/icons/admin.svg'
	defaults:
		menuOptions: []


	initialize: () =>
		@repositoryUrlTrinketModel = new RepositoryUrlTrinket.Model()
		@router = new Backbone.Router()


	fetchAllowedMenuOptions: () =>
		@clear()

		requestData =
			method: 'getMenuOptions'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
		
		socket.emit 'repos:read', requestData, (error, menuOptions) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error
			else
				@_processAllowedMenuOptions menuOptions


	_processAllowedMenuOptions: (menuOptions) =>
		assert.ok menuOptions.default in menuOptions.options

		allowedOptions = menuOptions.options.map (option) =>
			assert.ok @POSSIBLE_MENU_OPTIONS[option]?
			return @POSSIBLE_MENU_OPTIONS[option]

		@set 'menuOptions', allowedOptions,
			error: (model, error) => console.error error

		if not globalRouterModel.get('repositoryView')? or
				globalRouterModel.get('repositoryView') not in menuOptions.options
			globalRouterModel.set 'repositoryView', menuOptions.default,
				error: (model, error) => console.error error


	validate: (attributes) =>
		if not attributes.menuOptions?
			return new Error 'Must specify menu options'

		for option in attributes.menuOptions
			if not @POSSIBLE_MENU_OPTIONS[option.name]?
				return new Error 'Invalid option: ' + option

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
		globalRouterModel.on 'change:repositoryView', @_handleSelectedMenuOption, @

		@model.fetchAllowedMenuOptions()


	onDispose: () =>
		@model.off null, null, @
		globalRouterModel.off null, null, @

		@repositoryUrlTrinketView.dispose()


	render: () =>
		@$el.html @template options: @model.get 'menuOptions'
		@$('.repositoryMenuTrinkets').append @repositoryUrlTrinketView.render().el
		@_handleSelectedMenuOption()
		Tipped.create @$('.repositoryMenuOption'), skin: 'default'
		return @


	_handleClick: (event) =>
		optionName = $(event.target).attr 'optionName'
		assert.ok optionName?
		globalRouterModel.set 'repositoryView', optionName,
			error: (model, error) => console.error error


	_handleSelectedMenuOption: () =>
		@$('.repositoryMenuOption').removeClass 'selected'
		optionName = globalRouterModel.get 'repositoryView'
		@$(".repositoryMenuOption[optionName='#{optionName}']").addClass 'selected'
