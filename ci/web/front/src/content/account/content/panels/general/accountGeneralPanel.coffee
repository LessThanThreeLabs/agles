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
	html: '<div class="accountGeneralPanelContent">
			<div class="prettyForm">
				<div class="prettyFormRow">
					<div class="prettyFormLabel">First name</div>
					<div class="prettyFormValue">
						<input type="text" class="accountFirstName" placeholder="first" maxlength=256>
						<div class="prettyFormErrorText" type="firstName"></div>
					</div>
				</div>
				<div class="prettyFormRow">
					<div class="prettyFormLabel">Last name</div>
					<div class="prettyFormValue">
						<input type="text" class="accountLastName" placeholder="last" maxlength=256>
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
		@$el.html @html
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
		console.log '>> need to save account info'


	_clearErrors: () =>
		@$('.prettyFormErrorText').removeClass 'visible'


	_showErrors: (errors) =>
		@_clearErrors()

		for errorType, errorText of errors
			errorField = @$(".prettyFormErrorText[type='#{errorType}']")
			errorField.addClass 'visible'
			errorField.html errorText
