window.RepositoryAdminGithubPanel = {}


class RepositoryAdminGithubPanel.Model extends Backbone.Model
	defaults:
		forwardUrl: ''


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
					<div class="prettyFormLabel">Forward Url</div>
					<div class="prettyFormValue">
						<input type="text" class="repositoryForwardUrlField" maxlength=128 placeholder="git://github.com/awesome/repository.git">
						<div class="prettyFormErrorText" type="forwardUrl"></div>
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


	onDispose: () =>


	render: () =>
		@$el.html @html
		setTimeout (() => @$('.repositoryForwardUrlField').focus()), 0
		return @


	_handleFormEntryChange: () =>
		if event.keyCode is 13
			@_performSaveForwardUrlRequest()
		else
			@model.set 'forwardUrl', @$('.repositoryForwardUrlField').val(),
				error: (model, error) => console.error error


	_performSaveForwardUrlRequest: (event) =>
		console.log '>> Need to submit repository forward url change!'


	_clearErrors: () =>
		@$('.prettyFormErrorText').removeClass 'visible'


	_showErrors: (errors) =>
		@_clearErrors()

		for errorType, errorText of errors
			errorField = @$(".prettyFormErrorText[type='#{errorType}']")
			errorField.addClass 'visible'
			errorField.html errorText
