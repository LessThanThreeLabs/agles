window.LoginPanel = {}

# Since this panel is being added to the body, make sure it's only rendered once!
window.LoginPanel.renderedAlready = false


class LoginPanel.Model extends Backbone.Model
	defaults:
		mode: 'initialScreen'
		visible: false

	initialize: () =>
		@loginBasicInformationPanelModel = new LoginBasicInformationPanel.Model()
		@loginAdvancedInformationPanelModel = new LoginAdvancedInformationPanel.Model()


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
			</div>
		</div>'

	events:
		'click .createAccountButton': '_handleCreateAccountClick'
		'click .loginButton': '_handleLoginClick'


	initialize: () =>
		@loginBasicInformationPanelView = new LoginBasicInformationPanel.View model: @model.loginBasicInformationPanelModel
		@loginAdvancedInformationPanelView = new LoginAdvancedInformationPanel.View model: @model.loginAdvancedInformationPanelModel

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


	_loadInitialView: () =>
		@$el.find('.formContents').html @loginBasicInformationPanelView.render().el

		@$el.find('.loginButton').stop true, true
		@$el.find('.loginButton').show()


	_loadCreateAccountView: () =>
		@loginAdvancedInformationPanelView.$el.hide()

		@$el.find('.formContents').append '<div class="horizontalRule"></div>'
		@$el.find('.formContents').append @loginAdvancedInformationPanelView.render().el

		@loginAdvancedInformationPanelView.$el.show 500, () =>
			# only hide the login button if the modal is still open!
			if @model.get 'visible'
				@$el.find('.loginButton').hide 250


	_handleCreateAccountClick: () =>
		@model.set 'mode', 'createAccount'


	_handleLoginClick: () =>
		console.log 'login request'
		# @_makeLoginRequest()


	# _makeLoginRequest: () =>
	# 	requestData = 
	# 		email: @model.get 'email'
	# 		password: @model.get 'password'
	# 		rememberMe: @model.get 'rememberMe'
	# 	socket.emit 'users:update', requestData, (error, userData) =>
	# 		if error?
	# 			console.log error
	# 		else
	# 			console.log userData  # need to update login information
	# 			@model.set 'visible', false


	_updateVisibility: (model, visible) =>
		if visible 
			$('.loginModal').modal 'show'
		else 
			$('.loginModal').modal 'hide'
			@model.set 'mode', 'initial'
		