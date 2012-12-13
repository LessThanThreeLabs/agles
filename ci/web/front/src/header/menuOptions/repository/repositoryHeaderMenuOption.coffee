window.RepositoryHeaderMenuOption = {}


class RepositoryHeaderMenuOption.Model extends Backbone.Model
	defaults:
		repositories: null
		visible: true


	initialize: () =>
		options = [
			new PrettyDropdownOption('hello', 'Repository #1AAAAAAAA'),
			new PrettyDropdownOption('there', 'Repository #2')
			]
		@dropdownModel = new PrettyDropdown.Model 
			options: options
			alignment: 'right'


	fetchRepositories: () =>
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
	# html: '<div class="dropdown">
	# 		<span class="dropdown-toggle" data-toggle="dropdown" href="#">Repositories</span>
	# 		<ul class="dropdown-menu dropdownContents pull-right" role="menu"></ul>
	# 	</div>'
	# dropdownContentsTemplate: Handlebars.compile '{{#each repositories}}
	# 		<li><a class="repository" repositoryId={{this.id}}>{{this.name}}</a></li>
	# 	{{/each}}
	# 	{{#if repositories}}
	# 		<li class="divider"></li>
	# 	{{/if}}
	# 	<li><a class="createRepository">Create repository</a></li>'
	# events:
	# 	'click .repository': '_handleRepositorySelection'
	# 	'click .createRepository': '_handleCreateRepository'
	events: 'click .headerMenuOptionTitle': '_handleClick'


	initialize: () ->
		@dropdownView = new PrettyDropdown.View model: @model.dropdownModel

		# @model.on 'change:repositories', @_updateDropdownContents, @
		@model.on 'change:visible', @_fixVisibility, @

		globalAccount.on 'change', @model.fetchRepositories, @

		@model.fetchRepositories() if globalAccount.get 'email'


	onDispose: () =>
		@model.off null, null, @
		globalAccount.off null, null, @


	render: () =>
		@$el.html @html
		@$el.append @dropdownView.render().el
		# @_updateDropdownContents()
		return @


	_handleClick: (event) =>
		@model.dropdownModel.toggleVisibility()


	# _handleRepositorySelection: (event) =>
	# 	repositoryId = $(event.target).attr 'repositoryId'
	# 	repositoryId = if isNaN(parseInt(repositoryId)) then null else parseInt(repositoryId)
	# 	assert.ok repositoryId?

	# 	attributesToSet = 
	# 		view: 'repository'
	# 		repositoryId: repositoryId
	# 	globalRouterModel.set attributesToSet,
	# 		error: (model, error) => console.error error


	# _handleCreateRepository: (event) =>
	# 	globalRouterModel.set
	# 		view: 'createRepository'


	# _updateDropdownContents: () =>
	# 	@$el.find('.dropdownContents').html @dropdownContentsTemplate
	# 		repositories: @model.get 'repositories'


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'
