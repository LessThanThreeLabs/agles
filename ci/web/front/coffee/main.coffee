window.Main = {}


class Main.Model extends Backbone.Model
	ALLOWED_MODES: ['welcome', 'repository']

	defaults:
		mode: 'welcome'


	initialize: () =>
		@headerModel = new Header.Model()
		@welcomeModel = new Welcome.Model()
		@repositoryModel = new Repository.Model()


	validate: (attributes) =>
		if attributes.mode not in @ALLOWED_MODES
			return new Error 'Invalid mode'
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
				@$el.find('.contentContainer').html @welcomeView.render().el
			when 'repository'
				@$el.find('.contentContainer').html @repositoryView.render().el
			else	
				console.error 'Unaccounted for mode'


class Main.Router extends Backbone.Router
	routes:
		'': 'loadIndex'

		'repository/:repositoryId': 'loadRepository'
		'repository/:repositoryId/:repositoryMode': 'loadRepository'

	loadIndex: () =>
		mainModel.set 'mode', 'welcome'


	loadRepository: (repositoryId, repositoryMode) =>
		mainModel.set 'mode', 'repository'

		if repositoryId?
			mainModel.repositoryModel.set 'repositoryId', repositoryId
		if repositoryMode?
			mainModel.repositoryModel.set 'repositoryMode', repositoryMode



mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

mainRouter = new Main.Router()
