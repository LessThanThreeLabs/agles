window.AccountGeneralPanel = {}


class AccountGeneralPanel.Model extends Backbone.Model
	defaults:
		firstName: ''
		lastName: ''


	validate: (attributes) =>
		if typeof attributes.firstName isnt 'string'
			return new Error 'Invalid first name: ' + attributes.firstName

		if typeof attributes.lastName isnt 'string'
			return new Error 'Invalid last name: ' + attributes.lastName

		return


class AccountGeneralPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountGeneralPanel'
	template: Handlebars.compile '<div class="accountGeneralPanelContent">
			<div class="prettyForm">
				<div class="prettyFormRow">
					<div class="prettyFormLabel labelPadding">First name</div>
					<div class="prettyFormValue">
						<input type="text" class="accountFirstName" placeholder="{{firstName}}" maxlength=256>
						<div class="prettyFormErrorText" type="firstName"></div>
					</div>
				</div>
				<div class="prettyFormRow">
					<div class="prettyFormLabel labelPadding">Last name</div>
					<div class="prettyFormValue">
						<input type="text" class="accountLastName" placeholder="{{lastName}}" maxlength=256>
						<div class="prettyFormErrorText" type="lastName"></div>
					</div>
				</div>
			</div>
			<div class="saveAccountButtonContainer">
				<button class="saveAccountButton">Save</button>
			</div>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .saveAccountButton': '_performSaveAccountRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @template
			firstName: globalAccount.get 'firstName'
			lastName: globalAccount.get 'lastName'
		setTimeout (() => @$('.accountFirstName').focus()), 0
		return @


	_handleFormEntryChange: (event) =>
		if event.keyCode is 13
			@_performSaveAccountRequest()
		else
			attributesToSet =
				firstName: @$('.accountFirstName').val()
				lastName: @$('.accountLastName').val()
			@model.set attributesToSet, 
				error: (model, error) => console.error error


	_performSaveAccountRequest: () =>
		userUpdateData = 
			firstName: if @model.get('firstName') is '' then globalAccount.get('firstName') else @model.get 'firstName'
			lastName: if @model.get('lastName') is '' then globalAccount.get('lastName') else @model.get 'lastName'

		socket.emit 'users:update', userUpdateData, (errors, userData) =>
			if errors?
				@_showErrors errors
			else
				globalAccount.set
					firstName: userUpdateData.firstName
					lastName: userUpdateData.lastName
				globalNotificationManager.addNotification PrettyNotification.Types.SUCCESS, 'successfully changed user information'


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