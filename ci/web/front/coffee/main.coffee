window.Main = {}


class Main.Model extends Backbone.Model
	ALLOWED_MODES: ['welcome', 'repository']

	defaults:
		mode: 'welcome'
		repositoryNumber: null


	initialize: () =>
		@headerModel = new Header.Model()
		@welcomeModel = new Welcome.Model()
		@repositoryModel = new Repository.Model()


	validate: (attributes) =>
		if attributes.mode not in @ALLOWED_MODES
			return new Error 'Invalid mode'

		if attributes.mode is 'repository' and not attributes.repositoryNumber?
			return new Error 'No repository number provided'

		return


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	template: Handlebars.compile '<div class="headerContainer"></div><div class="contentContainer"></div>'

	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@welcomeView = new Welcome.View model: @model.welcomeModel
		@repositoryView = new Repository.View model: @model.repositoryModel

		@model.on 'change:mode change:repositoryNumber', () =>
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
				@_loadRepository @model.get 'repositoryNumber'
			else	
				console.error 'Unaccounted for mode'


	_loadWelcome: () =>
		@$el.find('.contentContainer').html @welcomeView.render().el
		console.log 'NEED TO UNSUBSCRIBE FROM REPO NOTIFICATIONS HERE!!'


	_loadRepository: (repositoryNumber) =>
		assert.ok repositoryNumber?
		@$el.find('.contentContainer').html @repositoryView.render().el


class Main.Router extends Backbone.Router
	routes:
		'': 'loadIndex'
		'repository/:repositoryNumber': 'loadRepsitory'

	loadIndex: () =>
		mainModel.set 'mode', 'welcome'


	loadRepsitory: (repositoryNumber) =>
		mainModel.set 
			mode: 'repository'
			repositoryNumber: repositoryNumber


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

mainRouter = new Main.Router()
