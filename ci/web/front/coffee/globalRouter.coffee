class GlobalRouterModel extends Backbone.Model
	VALID_VIEWS: ['welcome', 'account', 'repository', 'createRepository']
	VALID_REPOSITORY_VIEWS: ['source', 'changes', 'settings', 'admin']
	VALID_CHANGE_VIEWS: ['information', 'compilation', 'test']

	defaults:
		view: 'welcome'

		repositoryId: null
		repositoryView: null

		changeId: null
		changeView: null


	initialize: () =>
		@on 'change', @_navigate


	_navigate: () =>
		switch @get 'view'
			when 'welcome'
				globalRouter.navigate '/', trigger: true
			when 'account'
				globalRouter.navigate '/account', trigger: true
			when 'repository'
				@_navigateToRepository()
			when 'createRepository'
				globalRouter.navigate '/create/repository', trigger: true
			else
				console.error 'Unaccounted for view ' + @get 'view'


	_navigateToRepository: () =>
		assert.ok @get('view') is 'repository' 
		assert.ok @get('repositoryId')?

		url = '/repository/' + @get 'repositoryId'

		if @get('repositoryView')?
			url += '/' + @get 'repositoryView'

			if @get('repositoryView') is 'changes' and @get('changeId')?
				url += '/' + @get 'changeId'

				if @get('changeView')?
					url += '/' + @get 'changeView'

		globalRouter.navigate url, trigger: true


	validate: (attributes) =>
		if attributes.view? and attributes.view not in @VALID_VIEWS
			return new Error 'Invalid view: ' + attributes.view

		if attributes.repositoryId? and (typeof attributes.repositoryId isnt 'number' or attributes.repositoryId < 0)
			return new Error 'Invalid repository id (make sure it is not a string): ' + attributes.repositoryId

		if attributes.repositoryView? and attributes.repositoryView not in @VALID_REPOSITORY_VIEWS
			return new Error 'Invalid repository view: ' + attributes.repositoryView

		if attributes.changeId? and (typeof attributes.changeId isnt 'number' or attributes.changeId < 0)
			return new Error 'Invalid change id (make sure it is not a string): ' + attributes.changeId

		if attributes.changeView? and attributes.changeView not in @VALID_CHANGE_VIEWS
			return new Error 'Invalid change view: ' + attributes.changeView

		return


class GlobalRouter extends Backbone.Router
	routes:
		'': 'loadIndex'

		'account': 'loadAccount'

		'repository/:repositoryId': 'loadRepository'
		'repository/:repositoryId/:repositoryView': 'loadRepository'
		'repository/:repositoryId/changes/:changeId': 'loadRepositoryChange'
		'repository/:repositoryId/changes/:changeId/:changeView': 'loadRepositoryChange'

		'create/repository': 'createRepository'


	loadIndex: () =>
		attributesToSet =
			view: 'welcome'
			repositoryId: null
			repositoryView: null
			changeId: null
			changeView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	loadAccount: () =>
		attributesToSet =
			view: 'account'
			repositoryId: null
			repositoryView: null
			changeId: null
			changeView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	loadRepository: (repositoryId, repositoryView) =>
		attributesToSet =
			view: 'repository'
			repositoryId: if isNaN(parseInt(repositoryId)) then null else parseInt(repositoryId)
			repositoryView: repositoryView ? null
			changeId: null
			changeView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	loadRepositoryChange: (repositoryId, changeId, changeView) =>
		attributesToSet =
			view: 'repository'
			repositoryId: if isNaN(parseInt(repositoryId)) then null else parseInt(repositoryId)
			repositoryView: 'changes'
			changeId: if isNaN(parseInt(changeId)) then null else parseInt(changeId)
			changeView: changeView ? null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	createRepository: () =>
		attributesToSet =
			view: 'createRepository'
			repositoryId: null
			repositoryView: null
			changeId: null
			changeView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


globalRouterModel = new GlobalRouterModel()
globalRouter = new GlobalRouter()

window.globalRouterModel = globalRouterModel
