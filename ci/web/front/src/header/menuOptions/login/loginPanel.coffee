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
	html: '<div class="errorText">Invalid username/password combination</div>
		<div class="prettyForm">
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
			<a href="/account/create" class="createAccountOption">Create an account</a> | <a href="/recoverPassword" class="recoverPasswordOption">Recover password</a>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'change .loginRememberMe': '_handleFormEntryChange'
		'click .loginButton': '_performLoginRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		@_giveEmailFieldFocus()
		return @


	_giveEmailFieldFocus: () =>
		setTimeout (() => @$('.loginEmail').focus()), 0


	_handleFormEntryChange: (event) =>
		if event.keyCode is 13
			@_performLoginRequest()
		else
			@model.set
				email: @$('.loginEmail').val()
				password: @$('.loginPassword').val()
				rememberMe: @$('.loginRememberMe').prop 'checked'


	_performLoginRequest: () =>
		requestData = 
			method: 'login'
			args:
				email: @model.get 'email'
				password: @model.get 'password'
				rememberMe: @model.get 'rememberMe'

		socket.emit 'users:update', requestData, (error, userData) =>
			if error?
				@_changeErrorTextVisibility true
				console.error error
			else
				# window.location.reload()
				globalAccount.set
					email: userData.email
					firstName: userData.firstName
					lastName: userData.lastName
				@trigger 'loggedIn'


	_changeErrorTextVisibility: (visible) =>
		@$('.errorText').css 'display', if visible then 'block' else 'none'

