class GlobalRouterModel extends Backbone.Model
	VALID_VIEWS: ['global', 'sshKeys']

	defaults:
		view: 'global'


	initialize: () =>
		@on 'change:view', @_navigate


	_navigate: () =>
		switch @get 'view'
			when 'global'
				globalRouter.navigate '/global', trigger: true
			when 'sshKeys'
				globalRouter.navigate '/sshKeys', trigger: true
			else
				console.error 'Unaccounted for view ' + @get 'view'


	validate: (attributes) =>
		if attributes.view? and attributes.view not in @VALID_VIEWS
			return new Error 'Invalid view: ' + attributes.view

		return


class GlobalRouter extends Backbone.Router
	routes:
		':view': 'loadIndex'


	loadIndex: (view) =>
		globalRouterModel.set view: view,
			error: (model, error) => console.error error


globalRouterModel = new GlobalRouterModel()
globalRouter = new GlobalRouter()

window.globalRouterModel = globalRouterModel

Backbone.history.start
	root: '/account/'
	pushState: true
