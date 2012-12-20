window.HeaderMenuLoginOption = {}


class HeaderMenuLoginOption.Model extends Backbone.Model
	VALID_STATES: ['login', 'create']
	defaults:
		visible: false
		state: 'login'


	initialize: () =>
		@loginPanelModel = new LoginPanel.Model()
		@modalModel = new PrettyModal.Model()


	updateInformation: () =>
		# @set 'visible', not globalAccount.get('email')?
		@set 'visible', globalAccount.get('email')?


	validate: (attributes) =>
		if typeof attributes.visible isnt 'boolean'
			return new Error 'Invalid visibility: ' + attributes.visible

		if attributes.state not in @VALID_STATES
			return new Error 'Invalid state: ' + attributes.state

		return


class HeaderMenuLoginOption.View extends Backbone.View
	tagName: 'div'
	className: 'headerMenuLoginOption headerMenuOption'
	html: '<div class="headerMenuOptionTitle">Login</div>'
	events: 'click': '_clickHandler'
	currentView: null


	initialize: () =>
		@modalView = new PrettyModal.View model: @model.modalModel

		@model.on 'change', @render, @
		@model.modalModel.on 'change:visible', @_renderCurrentState
		globalAccount.on 'change', @model.updateInformation, @

		@model.updateInformation()


	onDispose: () =>
		@model.off null, null, @
		globalAccount.off null, null, @

		currentView.dispose() if currentView?


	render: () =>
		@$el.html @html
		@$el.append @modalView.render().el
		@_fixVisibility()
		return @


	_renderCurrentState: () =>
		currentView.dispose() if currentView?

		switch @model.get 'state'
			when 'login'
				currentView = new LoginPanel.View model: @model.loginPanelModel
				@modalView.setInnerHtml currentView.render().el
			when 'create'
				console.log 'need to make the create account page...'
			else
				console.error 'Unhandled state: ' + @model.get 'state'


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'


	_clickHandler: () =>
		@model.modalModel.set 'visible', true
		