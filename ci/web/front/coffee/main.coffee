window.Main = {}


class Main.Model extends Backbone.Model
	ALLOWED_MODES: ['welcome', 'repository']

	defaults:
		mode: 'welcome'


	initialize: () =>
		@headerModel = new Header.Model()

		@repositoryModel = new Repository.Model id: Math.floor Math.random() * 10000
		@repositoryModel.fetch()

		@welcomeModel = new Welcome.Model()


	validate: (attributes) =>
		if attributes.mode not in @ALLOWED_MODES
			return false

		return


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	template: Handlebars.compile '<div class="headerContainer"></div><div class="contentContainer"></div>'

	initialize: () ->
		@headerView = new Header.View model: @model.headerModel
		@repositoryView = new Repository.View model: @model.repositoryModel
		@welcomeView = new Welcome.View model: @model.welcomeModel

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
		'repository/:repositoryNumber': 'loadRepsitory'

	loadIndex: () =>
		mainModel.set 'mode', 'welcome'


	loadRepsitory: (repositoryNumber) =>
		console.log 'need to load repository ' + repositoryNumber
		mainModel.set 'mode', 'repository'


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

mainRouter = new Main.Router()
