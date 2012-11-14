window.Main = {}


class Main.Model extends Backbone.Model
	ALLOWED_MODES: ['welcome', 'account', 'repository', 'createRepository']

	defaults:
		mode: 'welcome'


	initialize: () =>
		@headerModel = new Header.Model()
		@welcomeModel = new Welcome.Model()
		@accountModel = new Account.Model()
		@repositoryModel = new Repository.Model()
		@createRepositoryModel = new CreateRepository.Model()


	validate: (attributes) =>
		if attributes.mode not in @ALLOWED_MODES
			return new Error 'Invalid mode'
		return


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	template: Handlebars.compile '<div class="headerContainer"></div><div class="contentContainer"></div>'

	initialize: () ->
		@model.on 'change:mode', () =>
			@_updateContent()


	render: () ->
		@$el.html @template()
		headerView = new Header.View model: @model.headerModel
		@$el.find('.headerContainer').append headerView.render().el
		@_updateContent()
		return @


	_updateContent: () =>
		switch @model.get 'mode'
			when 'welcome'
				welcomeView = new Welcome.View model: @model.welcomeModel
				@$el.find('.contentContainer').html welcomeView.render().el
			when 'account'
				accountView = new Account.View model: @model.accountModel
				@$el.find('.contentContainer').html accountView.render().el
			when 'repository'
				repositoryView = new Repository.View model: @model.repositoryModel
				@$el.find('.contentContainer').html repositoryView.render().el
			when 'createRepository'
				createRepositoryView = new CreateRepository.View model: @model.createRepositoryModel
				@$el.find('.contentContainer').html createRepositoryView.render().el
			else	
				console.error 'Unaccounted for mode'


class Main.Router extends Backbone.Router
	routes:
		'': 'loadIndex'

		'account': 'loadAccount'

		'repository/:repositoryId': 'loadRepository'
		'repository/:repositoryId/:repositoryMode': 'loadRepository'

		'create/repository': 'createRepository'

	loadIndex: () =>
		mainModel.set 'mode', 'welcome'


	loadAccount: () =>
		mainModel.set 'mode', 'account'
		

	loadRepository: (repositoryId, repositoryMode) =>
		mainModel.set 'mode', 'repository'

		if repositoryId?
			mainModel.repositoryModel.set 'repositoryId', repositoryId
		if repositoryMode?
			mainModel.repositoryModel.set 'repositoryMode', repositoryMode


	createRepository: () =>
		mainModel.set 'mode', 'createRepository'



mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

mainRouter = new Main.Router()
