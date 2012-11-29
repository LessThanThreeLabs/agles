window.Main = {}


class Main.Model extends Backbone.Model

	initialize: () =>
		@headerModel = new Header.Model()
		@welcomeModel = new Welcome.Model()
		@accountModel = new Account.Model()
		@repositoryModel = new Repository.Model()
		@createRepositoryModel = new CreateRepository.Model()


class Main.View extends Backbone.View
	tagName: 'div'
	id: 'main'
	currentView: null


	initialize: () ->
		window.globalRouterModel.on 'change:view', () =>
			@_updateContent()


	onDispose: () =>
		window.globalRouterModel.off 'change:view', null, @
		@currentView.dispose()


	render: () ->
		@$el.html '<div class="headerContainer"></div><div class="contentContainer"></div>'

		headerView = new Header.View model: @model.headerModel
		@$el.find('.headerContainer').html headerView.render().el

		@_updateContent()

		return @


	_updateContent: () =>
		@currentView.dispose() if @currentView?

		switch window.globalRouterModel.get 'view'
			when 'welcome'
				@currentView = new Welcome.View model: @model.welcomeModel
				@$el.find('.contentContainer').html @currentView.render().el
			when 'account'
				@currentView = new Account.View model: @model.accountModel
				@$el.find('.contentContainer').html @currentView.render().el
			when 'repository'
				@currentView = new Repository.View model: @model.repositoryModel
				@$el.find('.contentContainer').html @currentView.render().el
			when 'createRepository'
				@currentView = new CreateRepository.View model: @model.createRepositoryModel
				@$el.find('.contentContainer').html @currentView.render().el
			else	
				@currentView = null
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'view'


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el

window.mainView = mainView
