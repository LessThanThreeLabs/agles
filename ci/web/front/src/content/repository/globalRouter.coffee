class GlobalRouterModel extends Backbone.Model
	VALID_REPOSITORY_VIEWS: ['source', 'changes', 'settings', 'admin']
	VALID_CHANGE_VIEWS: ['information', 'compilation', 'test']

	defaults:
		repositoryId: null
		repositoryView: null
		changeId: null
		changeView: null


	initialize: () =>
		@on 'change:repositoryView change:changeId change:changeView', @_navigate


	_navigate: () =>
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
		if attributes.repositoryId? and (typeof attributes.repositoryId isnt 'number' or attributes.repositoryId < 0)
			return new Error 'Invalid repository id (make sure it is not a string): ' + attributes.repositoryId

		if attributes.repositoryView? and attributes.repositoryView not in @VALID_REPOSITORY_VIEWS
			return new Error 'Invalid repository view: ' + attributes.repositoryView

		if attributes.changeId? and (typeof attributes.changeId isnt 'number' or attributes.changeId < 0)
			return new Error 'Invalid change id (make sure it is not a string): ' + attributes.changeId

		if attributes.changeId? and attributes.repositoryView isnt 'changes'
			return new Error 'Invalid repository view when change id specified: ' + attributes.repositoryView

		if attributes.changeView? and attributes.changeView not in @VALID_CHANGE_VIEWS
			return new Error 'Invalid change view: ' + attributes.changeView

		return


class GlobalRouter extends Backbone.Router
	routes:
		'repository/:repositoryId': 'loadRepository'
		'repository/:repositoryId/:repositoryView': 'loadRepository'
		'repository/:repositoryId/:repositoryView/:changeId': 'loadRepository'
		'repository/:repositoryId/:repositoryView/:changeId/:changeView': 'loadRepository'


	loadRepository: (repositoryId, repositoryView, changeId, changeView) =>
		attributesToSet =
			repositoryId: if isNaN(parseInt(repositoryId)) then null else parseInt(repositoryId)
			repositoryView: repositoryView ? null
			changeId: if isNaN(parseInt(changeId)) then null else parseInt(changeId)
			changeView: changeView ? null
		globalRouterModel.set attributesToSet, 
			error: (model, error) => console.error error


globalRouterModel = new GlobalRouterModel()
globalRouter = new GlobalRouter()

window.globalRouterModel = globalRouterModel

Backbone.history.start pushState: true
