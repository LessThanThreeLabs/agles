window.CreateAccountPanel = {}

# Since this panel is being added to the body, make sure it's only rendered once!
window.CreateAccountPanel.renderedAlready = false


class CreateAccountPanel.Model extends Backbone.Model
	defaults:
		visible: false
		email: ''
		password: ''
		verifyPassword: ''
		firstName: ''
		lastName: ''

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
							<input type="text" class="createAccountEmail" placeholder="email"><span class="createEmailError help-inline"></span>
						</div>
					</div>
					<div class="control-group passwordControlGroup">
						<label class="control-label">Password</label>
						<div class="controls">
							<input type="password" class="createAccountPassword" placeholder="password"><span class="createPasswordError help-inline"></span>
						</div>
					</div>
					<div class="control-group verifyPasswordControlGroup">
						<label class="control-label">Verify Password</label>
						<div class="controls">
							<input type="password" class="createAccountVerifyPassword" placeholder="password again, for practice"><span class="createVerifyPasswordError help-inline"></span>
						</div>
					</div>
					<div class="horizontalRule"></div>
					<div class="control-group firstNameControlGroup">
						<label class="control-label">First Name</label>
						<div class="controls">
							<input type="password" class="createAccountFirstName" placeholder="first name"><span class="createFirstNameError help-inline"></span>
						</div>
					</div>
					<div class="control-group lastNameControlGroup">
						<label class="control-label">Last Name</label>
						<div class="controls">
							<input type="password" class="createAccountLastName" placeholder="last name"><span class="createLastNameError help-inline"></span>
						</div>
					</div>
				</form>
			</div>
			<div class="modal-footer">
				<a href="#" class="btn btn-primary createAccountButton">Create Account</a>
			</div>
		</div>'

	events:
		'keydown': '_handleFormEntryChange'
		'click .createAccountButton': '_handleCreateAccount'


	initialize: () =>
		@formValidator = new CreateAccountPanelValidator @model

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


	_handleFormEntryChange: () =>
		setTimeout (() =>
			@model.set 'email', $('.createAccountEmail').val()
			@model.set 'password', $('.createAccountPassword').val()
			@model.set 'verifyPassword', $('.createAccountVerifyPassword').val()
			@model.set 'firstName', $('.createAccountFirstName').val()
			@model.set 'lastName', $('.createAccountLastName').val()
			), 0


	_handleCreateAccount: () =>
		@_updateErrorMessages()
		if @formValidator.allValid()
			@_makeCreateAccountRequest()


	_makeCreateAccountRequest: () =>
		requestData = 
			email: @model.get 'email'
			password: @model.get 'password'
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
		socket.emit 'users:create', requestData, (error, userData) =>
			throw new Error error if error?
			console.log userData		


	_updateEmailErrorMessage: () =>
		if @formValidator.isEmailValid()
			$('.emailControlGroup').removeClass 'error'
			$('.createEmailError').text ''
		else
			$('.emailControlGroup').addClass 'error'
			$('.createEmailError').text 'Email address is invalid'


	_updatePasswordErrorMessage: () =>
		if @formValidator.isPasswordValid()
			$('.passwordControlGroup').removeClass 'error'
			$('.createPasswordError').text ''
		else
			$('.passwordControlGroup').addClass 'error'
			$('.createPasswordError').text 'Password must be 8 or more characters'


	_updatePasswordVerifyErrorMessage: () =>
		if @formValidator.isVerifyPasswordValid()
			$('.verifyPasswordControlGroup').removeClass 'error'
			$('.createVerifyPasswordError').text ''
		else
			$('.verifyPasswordControlGroup').addClass 'error'
			$('.createVerifyPasswordError').text 'Password does not match'


	_updateFirstNameErrorMessage: () =>
		if @formValidator.isFirstNameValid()
			$('.firstNameControlGroup').removeClass 'error'
			$('.createFirstNameError').text ''
		else
			$('.firstNameControlGroup').addClass 'error'
			$('.createFirstNameError').text 'Invalid first name'


	_updateLastNameErrorMessage: () =>
		if @formValidator.isLastNameValid()
			$('.lastNameControlGroup').removeClass 'error'
			$('.createLastNameError').text ''
		else
			$('.lastNameControlGroup').addClass 'error'
			$('.createLastNameError').text 'Invalid last name'


	_updateErrorMessages: () =>
		@_updateEmailErrorMessage()
		@_updatePasswordErrorMessage()
		@_updatePasswordVerifyErrorMessage()
		@_updateFirstNameErrorMessage()
		@_updateLastNameErrorMessage()


	_updateVisibility: (model, visible) =>
		if visible then $('.createAccountModal').modal 'show'
		else $('.createAccountModal').modal 'hide'
		