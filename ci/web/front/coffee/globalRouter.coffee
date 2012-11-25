class GlobalRouterModel extends Backbone.Model
	VALID_VIEWS: ['welcome', 'account', 'repository', 'createRepository']
	VALID_REPOSITORY_VIEWS: ['source', 'builds', 'settings', 'admin']

	defaults:
		view: null

		repositoryId: null
		repositoryView: null

		buildId: null
		buildView: null


	validate: (attributes) =>
		if attributes.view? and attributes.view not in @VALID_VIEWS
			return new Error 'Invalid view'

		if attributes.repositoryView? and attributes.repositoryView not in @VALID_REPOSITORY_VIEWS
			return new Error 'Invalid repository view'

		return


class GlobalRouter extends Backbone.Router
	routes:
		'': 'loadIndex'

		'account': 'loadAccount'

		'repository/:repositoryId': 'loadRepository'
		'repository/:repositoryId/:repositoryView': 'loadRepository'
		'repository/:repositoryId/builds/:buildId': 'loadRepositoryBuild'
		'repository/:repositoryId/builds/:buildId/:buildView': 'loadRepositoryBuild'

		'create/repository': 'createRepository'

	loadIndex: () =>
		attributesToSet =
			view: 'welcome'
			repositoryId: null
			repositoryView: null
			buildId: null
			buildView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	loadAccount: () =>
		attributesToSet =
			view: 'account'
			repositoryId: null
			repositoryView: null
			buildId: null
			buildView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	loadRepository: (repositoryId, repositoryView) =>
		attributesToSet =
			view: 'repository'
			repositoryId: repositoryId ? null
			repositoryView: repositoryView ? null
			buildId: null
			buildView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	loadRepositoryBuild: (repositoryId, buildId, buildView) =>
		attributesToSet =
			view: 'repository'
			repositoryId: repositoryId ? null
			repositoryView: 'builds'
			buildId: buildId ? null
			buildView: buildView ? null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


	createRepository: () =>
		attributesToSet =
			view: 'createRepository'
			repositoryId: null
			repositoryView: null
			buildId: null
			buildView: null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


globalRouterModel = new GlobalRouterModel()
globalRouter = new GlobalRouter()

window.globalRouterModel = globalRouterModel
