window.Main = {}


class Main.Model extends Backbone.Model
	ALLOWED_MODES: ['welcome', 'repository']

	defaults:
		mode: 'welcome'
		repositoryId: null


	initialize: () =>
		@headerModel = new Header.Model()
		@welcomeModel = new Welcome.Model()
		@repositoryModel = new Repository.Model()


	validate: (attributes) =>
		if attributes.mode not in @ALLOWED_MODES
			return new Error 'Invalid mode'

		if attributes.mode is 'repository' and not attributes.repositoryId?
			return new Error 'No repository id provided'

		return


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	template: Handlebars.compile '<div class="headerContainer"></div><div class="contentContainer"></div>'

	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@welcomeView = new Welcome.View model: @model.welcomeModel
		@repositoryView = new Repository.View model: @model.repositoryModel

		@model.on 'change:mode', () =>
			@_updateContent()


	render: () ->
		@$el.html @template()
		@$el.find('.headerContainer').append @headerView.render().el
		@_updateContent()
		return @


	_updateContent: () =>
		switch @model.get 'mode'
			when 'welcome'
				@_loadWelcome()
			when 'repository'
				@_loadRepository @model.get 'repositoryId'
			else	
				console.error 'Unaccounted for mode'


	_loadWelcome: () =>
		@$el.find('.contentContainer').html @welcomeView.render().el
		console.log 'NEED TO UNSUBSCRIBE FROM REPO NOTIFICATIONS HERE!!'


	_loadRepository: (repositoryId) =>
		assert.ok repositoryId?
		@model.repositoryModel.set 'repositoryId', repositoryId
		@$el.find('.contentContainer').html @repositoryView.render().el


class Main.Router extends Backbone.Router
	routes:
		'': 'loadIndex'
		'repository/:repositoryId': 'loadRepsitory'
		'repository/:repositoryId/:view': 'blah'

	loadIndex: () =>
		mainModel.set 'mode', 'welcome'


	loadRepsitory: (repositoryId) =>
		console.log 'loadRepsitory ' + repositoryId
		mainModel.set 
			mode: 'repository'
			repositoryId: repositoryId


	blah: (repositoryId, view) =>
		console.log 'blah ' + repositoryId + ' - ' + view


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

mainRouter = new Main.Router()
