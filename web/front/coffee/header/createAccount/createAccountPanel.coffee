window.CreateAccountPanel = {}

# Since this panel is being added to the body, make sure it's only rendered once!
window.CreateAccountPanel.renderedAlready = false


class CreateAccountPanel.Model extends Backbone.Model
	defaults:
		visible: false
		email: ''
		password: ''

	initialize: () =>


	toggleVisibility: () =>
		@set 'visible', not @get('visible')


class CreateAccountPanel.View extends Backbone.View
	tagName: 'div'
	className: 'createAccountPanel'
	template: Handlebars.compile '<div class="createAccountModal modal hide fade">
			<div class="modal-header">
				<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
				<h3>Create Account</h3>
			</div>
			<div class="modal-body">
				<form class="form-horizontal">
					<div class="control-group emailControlGroup">
						<label class="control-label">Email</label>
						<div class="controls">
							<input type="text" class="createAccountEmail" placeholder="email">
						</div>
					</div>
					<div class="control-group passwordControlGroup">
						<label class="control-label">Password</label>
						<div class="controls">
							<input type="password" class="createAccountPassword" placeholder="password"><span class="createPasswordError help-inline"></span>
						</div>
					</div>
				</form>
			</div>
			<div class="modal-footer">
				<a href="#" class="btn btn-primary createAccountButton">Create Account</a>
			</div>
		</div>'

	events:
		'keydown .createAccountEmail': '_handleEmailChange'
		'keydown .createAccountPassword': '_handlePasswordChange'
		'click .createAccountButton': '_handleCreateAccount'


	initialize: () =>
		@model.on 'change:visible', @_updateVisibility

		$(document).on 'show', '.createAccountModal', () =>
			@model.set 'visible', true
		$(document).on 'hide', '.createAccountModal', () =>
			@model.set 'visible', false


	render: () =>
		assert.ok not window.CreateAccountPanel.renderedAlready
		window.CreateAccountPanel.renderedAlready = true

		@$el.html @template()
		return @


	_handleEmailChange: (event) =>
		setTimeout (() => @model.set 'email', $('.createAccountEmail').val()), 0


	_handlePasswordChange: (event) =>
		setTimeout (() => @model.set 'password', $('.createAccountPassword').val()), 0


	_handleCreateAccount: () =>
		@_updatePasswordErrorMessage()
		if @_isPasswordValid()
			@_makeCreateAccountRequest()


	_isPasswordValid: () =>
		return @model.get('password').length > 8


	_makeCreateAccountRequest: () =>
		requestData = 
			email: @model.get 'email'
			password: @model.get 'password'
		socket.emit 'users:create', requestData, (error, userData) =>
			throw new Error error if error?
			console.log userData		


	_updatePasswordErrorMessage: () =>
		if @_isPasswordValid()
			$('.passwordControlGroup').removeClass 'error'
			$('.createPasswordError').text ''
		else
			$('.passwordControlGroup').addClass 'error'
			$('.createPasswordError').text 'Password must be 8 or more characters'


	_updateVisibility: (model, visible) =>
		if visible then $('.createAccountModal').modal 'show'
		else $('.createAccountModal').modal 'hide'
		