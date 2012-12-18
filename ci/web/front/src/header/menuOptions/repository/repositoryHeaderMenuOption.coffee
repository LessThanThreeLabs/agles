window.RepositoryHeaderMenuOption = {}


class RepositoryHeaderMenuOption.Model extends Backbone.Model
	CREATE_REPOSITORY_DROPDOWN_OPTION: new PrettyDropdownOption 'createRepository', 'Create Repository'
	defaults:
		repositories: null
		visible: true


	initialize: () =>
		options = [
			new PrettyDropdownOption(1, 'Repository #1AAAAAAAA'),
			new PrettyDropdownOption(2, 'Repository #2'),
			@CREATE_REPOSITORY_DROPDOWN_OPTION
			]
		@dropdownModel = new PrettyDropdown.Model 
			options: options
			alignment: 'right'


	fetchRepositories: () =>
		return if not globalAccount.get('email')?

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


class RepositoryHeaderMenuOption.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderMenuOption headerMenuOption'
	html: '<div class="headerMenuOptionTitle">Repositories</div>'
	events: 'click .headerMenuOptionTitle': '_handleClick'


	initialize: () ->
		@dropdownView = new PrettyDropdown.View model: @model.dropdownModel
		@dropdownView.on 'selected', @_handleRepositorySelection, @

		@model.on 'change:visible', @_fixVisibility, @
		globalAccount.on 'change', @model.fetchRepositories, @

		@model.fetchRepositories()


	onDispose: () =>
		@dropdownView.off null, null, @
		@model.off null, null, @
		globalAccount.off null, null, @

		@dropdownView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @dropdownView.render().el
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
