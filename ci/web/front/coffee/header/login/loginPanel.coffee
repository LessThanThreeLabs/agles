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
	template: Handlebars.compile '<div class="loginModal modal hide fade">
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

		@model.on 'change:mode', @_updateMode
		@model.on 'change:visible', @_updateVisibility

		$(document).on 'show', '.loginModal', () =>
			@model.set 'visible', true
		$(document).on 'hide', '.loginModal', () =>
			@model.set 'visible', false


	render: () =>
		assert.ok not window.LoginPanel.renderedAlready
		window.LoginPanel.renderedAlready = true

		@$el.html @template()
		@_loadInitialView()
		return @


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


	_loadInitialView: () =>
		@$el.find('.formContents').html @loginBasicInformationPanelView.render().el
		@_changeButtonVisibility @$el.find('.createAccountButton'), true
		@_changeButtonVisibility @$el.find('.loginButton'), true
		@_changeButtonVisibility @$el.find('.okButton'), false


	_loadCreateAccountView: () =>
		console.log 'rerendering issues!!'
		@$el.find('.formContents').html @loginBasicInformationPanelView.render().el
		@_changeButtonVisibility @$el.find('.createAccountButton'), true
		@_changeButtonVisibility @$el.find('.loginButton'), true
		@_changeButtonVisibility @$el.find('.okButton'), false

		@loginAdvancedInformationPanelView.$el.hide()

		@$el.find('.formContents').append '<div class="horizontalRule"></div>'
		@$el.find('.formContents').append @loginAdvancedInformationPanelView.render().el

		@loginAdvancedInformationPanelView.$el.show 500, () =>
			# only hide the login button if the modal is still open!
			if @model.get 'visible'
				@$el.find('.loginButton').hide 250


	_loadCreateAccountEmailSentView: () =>
		@$el.find('.formContents').html @loginCreateAccountEmailSentPanelView.render().el
		@_changeButtonVisibility @$el.find('.createAccountButton'), false
		@_changeButtonVisibility @$el.find('.loginButton'), false
		@_changeButtonVisibility @$el.find('.okButton'), true


	_handleCreateAccountClick: () =>
		if @model.get('mode') is 'initial'
			@model.set 'mode', 'createAccount'
		else if @model.get('mode') is 'createAccount'
			@_performCreateAccountRequest()


	_handleLoginClick: () =>
		console.log 'login request'
		# @_makeLoginRequest()


	_handleOkClick: () =>
		@model.set 'visible', false


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


	_makeLoginRequest: () =>
		requestData = 
			email: @model.loginBasicInformationPanelModel.get 'email'
			password: @model.loginBasicInformationPanelModel.get 'password'
			rememberMe: @model.loginBasicInformationPanelModel.get 'rememberMe'
		
		socket.emit 'users:update', requestData, (errors, userData) =>
			@loginBasicInformationPanelView.displayErrors errors

			if not errors?
				console.log userData  # need to update login information
				@model.set 'visible', false


	_updateVisibility: (model, visible) =>
		if visible 
			$('.loginModal').modal 'show'
		else 
			$('.loginModal').modal 'hide'
			@model.set 'mode', 'initial'
		