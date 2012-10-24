window.LoginPanel = {}

# Since this panel is being added to the body, make sure it's only rendered once!
window.LoginPanel.renderedAlready = false


class LoginPanel.Model extends Backbone.Model
	defaults:
		visible: false
		email: ''
		password: ''
		rememberMe: true

	initialize: () =>


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
			<div class="modal-body">
				<form class="form-horizontal">
					<div class="control-group emailControlGroup">
						<label class="control-label">Email</label>
						<div class="controls">
							<input type="text" class="loginEmail" placeholder="email">
						</div>
					</div>
					<div class="control-group passwordControlGroup">
						<label class="control-label">Password</label>
						<div class="controls loginPasswordControls">
							<input type="password" class="loginPassword" placeholder="password"><span class="loginPasswordError help-inline"></span>
						</div>
					</div>
					<div class="control-group">
						<div class="controls">
							<label class="checkbox">
								<input type="checkbox" class="loginRemember"> Remember me
							</label>
						</div>
					</div>
				</form>
			</div>
			<div class="modal-footer">
				<a href="#" class="btn btn-primary loginButton">Login</a>
			</div>
		</div>'

	events:
		'keydown': '_handleFormEntryChange'
		'change .loginRemember': '_handleFormEntryChange'
		'click .loginButton': '_handleLoginRequest'


	initialize: () =>
		@model.on 'change:visible', @_updateVisibility

		$(document).on 'show', '.loginModal', () =>
			@model.set 'visible', true
		$(document).on 'hide', '.loginModal', () =>
			@model.set 'visible', false


	render: () =>
		assert.ok not window.LoginPanel.renderedAlready
		window.LoginPanel.renderedAlready = true

		@$el.html @template()
		return @


	_handleFormEntryChange: () =>
		setTimeout (() =>
			@model.set 'email', $('.loginEmail').val()
			@model.set 'password', $('.loginPassword').val()
			@model.set 'rememberMe', $('.loginRemember').prop 'checked'
			), 0


	_handleLoginRequest: () =>
		@_updatePasswordErrorMessage()
		if @_isPasswordValid()
			@_makeLoginRequest()


	_isPasswordValid: () =>
		return @model.get('password').length > 8


	_makeLoginRequest: () =>
		requestData = 
			email: @model.get 'email'
			password: @model.get 'password'
			rememberMe: @model.get 'rememberMe'
		socket.emit 'users:update', requestData, (error, userData) =>
			throw new Error error if error?
			console.log userData		


	_updatePasswordErrorMessage: () =>
		if @_isPasswordValid()
			$('.passwordControlGroup').removeClass 'error'
			$('.loginPasswordError').text ''
		else
			$('.passwordControlGroup').addClass 'error'
			$('.loginPasswordError').text 'Password must be 8 or more characters'


	_updateVisibility: (model, visible) =>
		if visible then $('.loginModal').modal 'show'
		else $('.loginModal').modal 'hide'
		