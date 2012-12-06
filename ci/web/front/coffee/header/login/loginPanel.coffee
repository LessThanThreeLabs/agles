window.LoginPanel = {}

# Since this panel is being added to the body, make sure it's only rendered once!
window.LoginPanel.renderedAlready = false


class LoginPanel.Model extends Backbone.Model
	defaults:
		mode: 'initial'
		visible: false


	initialize: () =>
		@loginBasicInformationPanelModel = new LoginBasicInformationPanel.Model()
		@loginAdvancedInformationPanelModel = new LoginAdvancedInformationPanel.Model()
		@loginCreateAccountEmailSentPanelModel = new LoginCreateAccountEmailSentPanel.Model()

		@loginBasicInformationPanelModel.on 'change:email', () =>
			@loginCreateAccountEmailSentPanelModel.set 'email', @loginBasicInformationPanelModel.get 'email'
		@loginAdvancedInformationPanelModel.on 'change:firstName', () =>
			@loginCreateAccountEmailSentPanelModel.set 'firstName', @loginAdvancedInformationPanelModel.get 'firstName'
		@loginAdvancedInformationPanelModel.on 'change:lastName', () =>
			@loginCreateAccountEmailSentPanelModel.set 'lastName', @loginAdvancedInformationPanelModel.get 'lastName'


	toggleVisibility: () =>
		@set 'visible', not @get('visible')


class LoginPanel.View extends Backbone.View
	tagName: 'div'
	className: 'loginPanel'
	html: '<div class="loginModal modal hide fade">
			<div class="modal-header">
				<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
				<h3>Login</h3>
			</div>
			<div class="modal-body formContents">
				<!-- Content goes here -->
			</div>
			<div class="modal-footer">
				<a href="#" class="btn btn-primary createAccountButton">Create Account</a>
				<a href="#" class="btn btn-primary loginButton">Login</a>
				<a href="#" class="btn btn-primary okButton">Ok</a>
			</div>
		</div>'
	events:
		'click .createAccountButton': '_handleCreateAccountClick'
		'click .loginButton': '_handleLoginClick'
		'click .okButton': '_handleOkClick'


	initialize: () =>
		@loginBasicInformationPanelView = new LoginBasicInformationPanel.View model: @model.loginBasicInformationPanelModel
		@loginAdvancedInformationPanelView = new LoginAdvancedInformationPanel.View model: @model.loginAdvancedInformationPanelModel
		@loginCreateAccountEmailSentPanelView = new LoginCreateAccountEmailSentPanel.View model: @model.loginCreateAccountEmailSentPanelModel

		@model.on 'change:mode', @_updateMode, @
		@model.on 'change:visible', @_updateVisibility, @

		$(document).on 'show', '.loginModal', () =>
			@model.set 'visible', true
		$(document).on 'hide', '.loginModal', () =>
			@model.set 'visible', false


	onDispose: () =>
		@model.off null, null, @

		@loginBasicInformationPanelView.dispose()
		@loginAdvancedInformationPanelView.dispose()
		@loginCreateAccountEmailSentPanelView.dispose()

		console.log 'need to dispose of document events'


	render: () =>
		assert.ok not window.LoginPanel.renderedAlready
		window.LoginPanel.renderedAlready = true

		@$el.html @html

		@$el.find('.formContents').append @loginBasicInformationPanelView.render().el
		@$el.find('.formContents').append @loginAdvancedInformationPanelView.render().el
		@$el.find('.formContents').append @loginCreateAccountEmailSentPanelView.render().el

		@_loadInitialView()

		return @


	_handleCreateAccountClick: () =>
		if @model.get('mode') is 'initial'
			@model.set 'mode', 'createAccount'
		else if @model.get('mode') is 'createAccount'
			@_performCreateAccountRequest()


	_handleLoginClick: () =>
		@_performLoginRequest()


	_handleOkClick: () =>
		@model.set 'visible', false


	_updateMode: (model, mode) =>
		if mode is 'initial'
			@_loadInitialView()
		else if mode is 'createAccount'
			@_loadCreateAccountView()
		else if mode is 'createAccountEmailSent'
			@_loadCreateAccountEmailSentView()


	_changeButtonVisibility: (button, visible) =>
		button.stop true, true
		if visible then button.show()
		else button.hide()


	_changeButtonVisibilities: (createAccountButtonVisible, loginButtonVisible, okButtonVisible) =>
		@_changeButtonVisibility @$el.find('.createAccountButton'), createAccountButtonVisible
		@_changeButtonVisibility @$el.find('.loginButton'), loginButtonVisible
		@_changeButtonVisibility @$el.find('.okButton'), okButtonVisible


	_changePanelVisibility: (panel, visible) =>
		if visible then panel.show()
		else panel.hide()


	_changePanelVisibilities: (basicInformationPanelVisible, advancedInformationPanelVisible, emailSentVisible) =>
		@_changePanelVisibility @loginBasicInformationPanelView.$el, basicInformationPanelVisible
		@_changePanelVisibility @loginAdvancedInformationPanelView.$el, advancedInformationPanelVisible
		@_changePanelVisibility @loginCreateAccountEmailSentPanelView.$el, emailSentVisible


	_loadInitialView: () =>
		@_changePanelVisibilities true, false, false
		@_changeButtonVisibilities true, true, false


	_loadCreateAccountView: () =>
		@_changePanelVisibilities true, false, false
		@_changeButtonVisibilities true, true, false

		@loginAdvancedInformationPanelView.$el.show 500, () =>
			# only hide the login button if the modal is still open!
			if @model.get 'visible'
				@$el.find('.loginButton').hide 250


	_loadCreateAccountEmailSentView: () =>
		@_changePanelVisibilities false, false, true
		@_changeButtonVisibilities false, false, true


	_performCreateAccountRequest: () =>
		requestData =
			email: @model.loginBasicInformationPanelModel.get 'email'
			password: @model.loginBasicInformationPanelModel.get 'password'
			rememberMe: @model.loginBasicInformationPanelModel.get 'rememberMe'
			firstName: @model.loginAdvancedInformationPanelModel.get 'firstName'
			lastName: @model.loginAdvancedInformationPanelModel.get 'lastName'

		socket.emit 'users:create', requestData, (errors, result) =>
			@loginBasicInformationPanelView.displayErrors errors
			@loginAdvancedInformationPanelView.displayErrors errors

			if not errors?
				@model.set 'mode', 'createAccountEmailSent'


	_performLoginRequest: () =>
		requestData = 
			method: 'login'
			args:
				email: @model.loginBasicInformationPanelModel.get 'email'
				password: @model.loginBasicInformationPanelModel.get 'password'
				rememberMe: @model.loginBasicInformationPanelModel.get 'rememberMe'
		
		socket.emit 'users:update', requestData, (errors, userData) =>
			@loginBasicInformationPanelView.displayErrors errors

			if not errors?
				window.globalAccount.set
					email: userData.email
					firstName: userData.firstName
					lastName: userData.lastName
				@model.set 'visible', false


	_updateVisibility: (model, visible) =>
		if visible 
			$('.loginModal').modal 'show'
		else 
			$('.loginModal').modal 'hide'
			@model.set 'mode', 'initial'

			@loginBasicInformationPanelView.clear()
			@loginAdvancedInformationPanelView.clear()
		