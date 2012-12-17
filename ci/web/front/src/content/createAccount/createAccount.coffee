window.CreateAccount = {}


class CreateAccount.Model extends Backbone.Model
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


class CreateAccount.View extends Backbone.View
	tagName: 'div'
	className: 'createAccount'
	html: '<div class="prettyForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Email</div>
				<div class="prettyFormValue">
					<input type="email" class="createAccountEmail" placeholder="email" maxlength=256 autocomplete="on">
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Password</div>
				<div class="prettyFormValue">
					<input type="password" class="createAccountPassword" placeholder="password" maxlength=256>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Confirm password</div>
				<div class="prettyFormValue">
					<input type="password" class="createAccountConfirmPassword" placeholder="password, again" maxlength=256>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">First name</div>
				<div class="prettyFormValue">
					<input type="text" class="createAccountFirstName" placeholder="first" maxlength=256>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Last name</div>
				<div class="prettyFormValue">
					<input type="text" class="createAccountLastName" placeholder="last" maxlength=256>
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
			@model.set
				email: @$('.createAccountEmail').val()
				password: @$('.createAccountPassword').val()
				confirmPassword: @$('.createAccountConfirmPassword').val()
				firstName: @$('.createAccountFirstName').val()
				lastName: @$('.createAccountLastName').val()
				rememberMe: @$('.createAccountRememberMe').prop 'checked'


	_performCreateAccountRequest: () =>
		console.log '>> need to perform create account request'
