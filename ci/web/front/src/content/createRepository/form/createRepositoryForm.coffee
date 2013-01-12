window.CreateRepositoryForm = {}


class CreateRepositoryForm.Model extends Backbone.Model
	defaults:
		name: ''
		description: ''


	validate: (attributes) =>
		if typeof attributes.name isnt 'string'
			return new Error 'Invalid name: ' + attributes.name

		if typeof attributes.description isnt 'string'
			return new Error 'Invalid description: ' + attributes.description

		return


class CreateRepositoryForm.View extends Backbone.View
	tagName: 'div'
	className: 'createRepositoryForm'
	html: '<div class="prettyForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel labelPadding">Name</div>
				<div class="prettyFormValue">
					<input type="text" class="createRepositoryName" placeholder="name" maxlength=128 autocomplete="on">
					<div class="prettyFormErrorText" type="name"></div>
				</div>
			</div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel labelPadding">Description</div>
				<div class="prettyFormValue">
					<textarea type="text" class="createRepositoryDescription" placeholder="description" maxlength=500></textarea>
					<div class="prettyFormErrorText" type="description"></div>
				</div>
			</div>
		</div>
		<div class="createRepositoryButtonContainer">
			<button class="createRepositoryButton">Create</button>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'change .createRepositoryRememberMe': '_handleFormEntryChange'
		'click .createRepositoryButton': '_performCreateRepositoryRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_handleFormEntryChange: (event) =>
		attributesToSet = 
			name: @$('.createRepositoryName').val()
			description: @$('.createRepositoryDescription').val()
		@model.set attributesToSet, 
			error: (model, error) => console.error error


	_performCreateRepositoryRequest: () =>
		requestData =
			name: @model.get 'name'
			description: @model.get 'description'
			defaultPermissions: 'r/w'

		socket.emit 'repos:create', requestData, (errors, repositoryId) =>
			if errors?
				@_showErrors errors
			else
				window.location.href = '/repository/' + repositoryId


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

