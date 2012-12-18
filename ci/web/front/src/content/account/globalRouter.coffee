class GlobalRouterModel extends Backbone.Model
	VALID_VIEWS: ['general', 'password', 'sshKeys']

	defaults:
		view: 'general'


	initialize: () =>
		@on 'change:view', @_navigate


	_navigate: () =>
		switch @get 'view'
			when 'general'
				globalRouter.navigate '/account/general', trigger: true
			when 'password'
				globalRouter.navigate '/account/password', trigger: true
			when 'sshKeys'
				globalRouter.navigate '/account/sshKeys', trigger: true
			else
				console.error 'Unaccounted for view ' + @get 'view'


	validate: (attributes) =>
		if attributes.view? and attributes.view not in @VALID_VIEWS
			return new Error 'Invalid view: ' + attributes.view

		return


class GlobalRouter extends Backbone.Router
	routes:
		'account/:view': 'loadAccountView'


	loadAccountView: (view) =>
		globalRouterModel.set view: view ? null,
			error: (model, error) => console.error error


globalRouterModel = new GlobalRouterModel()
globalRouter = new GlobalRouter()

window.globalRouterModel = globalRouterModel

Backbone.history.start pushState: true
