window.RepositoryAdminGithubPanel = {}


class RepositoryAdminGithubPanel.Model extends Backbone.Model
	defaults:
		forwardUrl: ''
		publicKey: ''


	getPublicKey: () =>
		requestData = id: globalRouterModel.get 'repositoryId'
		socket.emit 'repos:read', requestData, (error, data) =>
			if error?
				globalRouterModel.set 'view', 'invalidRepositoryState' if error is 403
				console.error error
			else
				@set 'publicKey', data.publicKey,
					error: (model, error) => console.error error


	validate: (attributes) =>
		if typeof attributes.forwardUrl isnt 'string'
			return new Error 'Invalid forward url: ' + attributes.forwardUrl

		return


class RepositoryAdminGithubPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminGithubPanel'
	html: '<div class="repositoryAdminGithubPanelContent">
			<div class="prettyForm">
				<div class="prettyFormRow">
					<div class="prettyFormLabel labelPadding">Forward Url</div>
					<div class="prettyFormValue">
						<input type="text" class="repositoryForwardUrlField" maxlength=256 placeholder="git@github.com:awesome/repository.git">
						<div class="prettyFormErrorText" type="forwardUrl"></div>
					</div>
				</div>
				<div class="prettyFormRow">
					<div class="prettyFormLabel labelPadding">Public Key</div>
					<div class="prettyFormValue">
						<textarea type="text" class="publicKeyValue" readonly></textarea>
					</div>
				</div>
			</div>
			<div class="saveForwardUrlButtonContainer">
				<button class="saveForwardUrlButton">Save</button>
			</div>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .saveForwardUrlButton': '_performSaveForwardUrlRequest'


	initialize: () =>
		@model.on 'change:publicKey', @_updatePublicKey, @
		@model.getPublicKey()


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @html
		@_updatePublicKey()
		setTimeout (() => @$('.repositoryForwardUrlField').focus()), 0
		return @


	_updatePublicKey: () =>
		@$('.publicKeyValue').val @model.get 'publicKey'


	_handleFormEntryChange: () =>
		if event.keyCode is 13
			@_performSaveForwardUrlRequest()
		else
			@model.set 'forwardUrl', @$('.repositoryForwardUrlField').val(),
				error: (model, error) => console.error error


	_performSaveForwardUrlRequest: (event) =>
		requestData =
			method: 'updateForwardUrl'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
				forwardUrl: @model.get 'forwardUrl'

		socket.emit 'repos:update', requestData, (errors, callback) =>
			if errors?
				@_showErrors errors
			else
				globalNotificationManager.addNotification PrettyNotification.Types.SUCCESS, 'successfully updated forward url'


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
