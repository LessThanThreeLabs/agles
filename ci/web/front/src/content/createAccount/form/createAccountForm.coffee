window.CreateAccountForm = {}


class CreateAccountForm.Model extends Backbone.Model
	defaults:
		email: ''
		password: ''
		confirmPassword: ''
		firstName: ''
		lastName: ''
		rememberMe: false


	validate: (attributes) =>
		if typeof attributes.email isnt 'string'
			return new Error 'Invalid email: ' + attributes.email

		if typeof attributes.password isnt 'string'
			return new Error 'Invalid password: ' + attributes.password

		if typeof attributes.confirmPassword isnt 'string'
			return new Error 'Invalid confirm password: ' + attributes.confirmPassword

		if typeof attributes.firstName isnt 'string'
			return new Error 'Invalid first name: ' + attributes.firstName

		if typeof attributes.lastName isnt 'string'
			return new Error 'Invalid last name: ' + attributes.lastName

		if typeof attributes.rememberMe isnt 'boolean'
			return new Error 'Invalid remember me option: ' + attributes.rememberMe

		return


class CreateAccountForm.View extends Backbone.View
	tagName: 'div'
	className: 'createAccountForm'
	html: '<div class="prettyForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Email</div>
				<div class="prettyFormValue">
					<input type="email" class="createAccountEmail" placeholder="email" maxlength=256 autocomplete="on">
					<div class="prettyFormErrorText" type="email"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Password</div>
				<div class="prettyFormValue">
					<input type="password" class="createAccountPassword" placeholder="password" maxlength=256>
					<div class="prettyFormErrorText" type="password"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Confirm password</div>
				<div class="prettyFormValue">
					<input type="password" class="createAccountConfirmPassword" placeholder="password, again" maxlength=256>
					<div class="prettyFormErrorText" type="confirmPassword"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">First name</div>
				<div class="prettyFormValue">
					<input type="text" class="createAccountFirstName" placeholder="first" maxlength=256>
					<div class="prettyFormErrorText" type="firstName"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Last name</div>
				<div class="prettyFormValue">
					<input type="text" class="createAccountLastName" placeholder="last" maxlength=256>
					<div class="prettyFormErrorText" type="lastName"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel"></div>
				<div class="prettyFormValue">
					<input type="checkbox" class="createAccountRememberMe"> Remember me
				</div>
			</div>
		</div>
		<div class="createAccountButtonContainer">
			<button class="createAccountButton">Create</button>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'change .createAccountRememberMe': '_handleFormEntryChange'
		'click .createAccountButton': '_performCreateAccountRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_handleFormEntryChange: (event) =>
		if event.keyCode is 13
			@_performCreateAccountRequest()
		else
			attributesToSet = 
				email: @$('.createAccountEmail').val()
				password: @$('.createAccountPassword').val()
				confirmPassword: @$('.createAccountConfirmPassword').val()
				firstName: @$('.createAccountFirstName').val()
				lastName: @$('.createAccountLastName').val()
				rememberMe: @$('.createAccountRememberMe').prop 'checked'
			@model.set attributesToSet, 
				error: (model, error) => console.error error


	_performCreateAccountRequest: () =>
		requestData =
			email: @model.get 'email'
			password: @model.get 'password'
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
			rememberMe: @model.get 'rememberMe'

		if requestData.password != @model.get 'confirmPassword'
			globalNotificationManager.addNotification PrettyNotification.Types.ERROR, 'Passwords do not match'
			return

		socket.emit 'users:create', requestData, (errors, result) =>
			if errors?
				@_showErrors errors
			else
				@trigger 'accountCreated'


	_clearErrors: () =>
		@$('.prettyFormErrorText').removeClass 'visible'


	_showErrors: (errors) =>
		@_clearErrors()

		if typeof errors is 'string'
			globalNotificationManager.addNotification PrettyNotification.Types.ERROR, errors
			return

		for errorType, errorText of errors
			errorField = @$(".prettyFormErrorText[type='#{errorType}']")
			errorField.addClass 'visible'
			errorField.html errorText

