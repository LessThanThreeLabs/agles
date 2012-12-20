window.HeaderMenuRepositoryOption = {}


class HeaderMenuRepositoryOption.Model extends Backbone.Model
	CREATE_REPOSITORY_DROPDOWN_OPTION: new PrettyDropdownOption 'createRepository', 'Create Repository'
	defaults:
		repositories: []
		visible: true


	initialize: () =>
		@dropdownModel = new PrettyDropdown.Model alignment: 'right'

		@on 'change:repositories', @_setDropdownOptions
		@_setDropdownOptions()


	_setDropdownOptions: () =>
		dropdownOptions = []
		for repository in @get 'repositories'
			dropdownOptions.push new PrettyDropdownOption repository.id, repository.name
		dropdownOptions.push @CREATE_REPOSITORY_DROPDOWN_OPTION

		attributesToSet = options: dropdownOptions
		@dropdownModel.set attributesToSet,
			error: (model, error) => console.error error


	fetchRepositories: () =>
		return if not globalAccount.get 'loggedIn'

		requestData = 
			method: 'writableRepositories'
			args: {}

		socket.emit 'repos:read', requestData, (error, repositoriesData) =>
			if error?
				console.log error
				return
	
			@set 'repositories', repositoriesData,
				error: (model, error) => console.error error


	validate: (attributes) =>
		for repository in attributes.repositories
			if not repository.id? or repository.id < 0 or not repository.name? or repository.name is ''
				return new Error 'Invalid repository'
		return


class HeaderMenuRepositoryOption.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenuRepositoryOption headerMenuOption'
	html: '<div class="headerMenuOptionTitle">Repositories</div>'
	events: 'click .headerMenuOptionTitle': '_handleClick'


	initialize: () ->
		@dropdownView = new PrettyDropdown.View model: @model.dropdownModel
		@dropdownView.on 'selected', @_handleRepositorySelection, @

		@model.on 'change:visible', @_fixVisibility, @
		globalAccount.on 'change:loggedIn', @model.fetchRepositories, @

		@model.fetchRepositories()


	onDispose: () =>
		@dropdownView.off null, null, @
		@model.off null, null, @
		globalAccount.off null, null, @

		@dropdownView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @dropdownView.render().el
		@_fixVisibility()
		return @


	_handleRepositorySelection: (repositoryName) =>
		if repositoryName is @model.CREATE_REPOSITORY_DROPDOWN_OPTION.name
			window.location.href = '/repository/create'
		else
			window.location.href = '/repository/' + repositoryName


	_handleClick: (event) =>
		@model.dropdownModel.toggleVisibility()


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'
