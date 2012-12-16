window.LoginPanel = {}


class LoginPanel.Model extends Backbone.Model
	defaults:
		email: ''
		password: ''
		rememberMe: false


	validate: (attributes) =>
		if typeof attributes.email isnt 'string'
			return new Error 'Invalid email: ' + attributes.email

		if typeof attributes.password isnt 'string'
			return new Error 'Invalid password: ' + attributes.password

		if typeof attributes.rememberMe isnt 'boolean'
			return new Error 'Invalid remember me option: ' + attributes.rememberMe

		return


class LoginPanel.View extends Backbone.View
	tagName: 'div'
	className: 'loginPanel'
	html: '<div class="prettyForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Email</div>
				<div class="prettyFormValue">
					<input type="email" class="loginEmail" placeholder="email" maxlength=256 autocomplete="on">
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">Password</div>
				<div class="prettyFormValue">
					<input type="password" class="loginPassword" placeholder="password" maxlength=256>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel"></div>
				<div class="prettyFormValue">
					<input type="checkbox" class="loginRememberMe"> Remember me
				</div>
			</div>
		</div>
		<div class="loginButtonContainer">
			<button class="loginButton">Login</button>
		</div>
		<div class="memberOptions">
			<div class="memberOptionsTitle">Not a member?</div>
			<a href="createAccount" class="createAccountOption">Create an account</a> | <a href="recoverPassword" class="recoverPasswordOption">Recover password</a>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'change .loginRememberMe': '_handleFormEntryChange'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_handleFormEntryChange: (event) =>
		@model.set
			email: @$('.loginEmail').val()
			password: @$('.loginPassword').val()
			rememberMe: @$('.loginRememberMe').prop 'checked'
