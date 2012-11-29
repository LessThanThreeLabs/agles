window.RepositoryHeaderOption = {}


class RepositoryHeaderOption.Model extends Backbone.Model
	defaults:
		repositories: null
		visible: true


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


class RepositoryHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderOption headerMenuOption'
	html: '<div class="dropdown">
			<span class="dropdown-toggle" data-toggle="dropdown" href="#">Repositories</span>
			<ul class="dropdown-menu dropdownContents pull-right" role="menu"></ul>
		</div>'
	dropdownContentsTemplate: Handlebars.compile '{{#each repositories}}
			<li><a class="repository" repositoryId={{this.id}}>{{this.name}}</a></li>
		{{/each}}
		{{#if repositories}}
			<li class="divider"></li>
		{{/if}}
		<li><a class="createRepository">Create repository</a></li>'
	events:
		'click .repository': '_handleRepositorySelection'
		'click .createRepository': '_handleCreateRepository'


	initialize: () ->
		@model.on 'change:repositories', @_updateDropdownContents
		@model.on 'change:visible', @_fixVisibility

		window.globalAccount.on 'change:firstName change:lastName', () =>
			@model.fetchRepositories()


	onDispose: () =>
		@model.off null, null, @
		window.globalAccount.off null, null, @


	render: () ->
		@$el.html @html
		@_updateDropdownContents()
		return @


	_handleRepositorySelection: (event) =>
		repositoryId = $(event.target).attr 'repositoryId'
		assert.ok repositoryId?

		window.globalRouterModel.set
			view: 'repository'
			repositoryId: repositoryId


	_handleCreateRepository: (event) =>
		window.globalRouterModel.set
			view: 'createRepository'


	_updateDropdownContents: () =>
		@$el.find('.dropdownContents').html @dropdownContentsTemplate
			repositories: @model.get 'repositories'


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'
