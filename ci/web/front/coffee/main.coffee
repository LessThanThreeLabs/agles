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
	template: Handlebars.compile '<div class="headerContainer"></div><div class="contentContainer"></div>'

	initialize: () ->
		window.globalRouterModel.on 'change:view', () =>
			@_updateContent()


	render: () ->
		@$el.html @template()
		headerView = new Header.View model: @model.headerModel
		@$el.find('.headerContainer').append headerView.render().el
		@_updateContent()
		return @


	_updateContent: () =>
		switch window.globalRouterModel.get 'view'
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
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'view'


mainModel = new Main.Model()

mainView = new Main.View model: mainModel
$('body').prepend mainView.render().el
