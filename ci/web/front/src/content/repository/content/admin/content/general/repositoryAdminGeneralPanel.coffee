window.RepositoryAdminGeneralPanel = {}


class RepositoryAdminGeneralPanel.Model extends Backbone.Model
	defaults:
		description: ''


	validate: (attributes) =>
		if typeof attributes.description isnt 'string'
			return new Error 'Invalid description: ' + attributes.description

		return


class RepositoryAdminGeneralPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminGeneralPanel'
	html: '<div class="repositoryAdminGeneralPanelContent">
			<div class="prettyForm">
				<div class="prettyFormRow">
					<div class="prettyFormLabel">Description</div>
					<div class="prettyFormValue">
						<textarea type="text" class="repositoryDescriptionField" placeholder="description" maxlength=256></textarea>
						<div class="prettyFormErrorText" type="description"></div>
					</div>
				</div>
			</div>
			<div class="saveDescriptionButtonContainer">
				<button class="saveDescriptionButton">Save</button>
			</div>
		</div>'
	events:
		'keyup': '_handleFormEntryChange'
		'click .saveDescriptionButton': '_performSaveDescriptionRequest'


	initialize: () =>


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @


	_handleFormEntryChange: () =>
		@model.set 'description', @$('.repositoryDescriptionField').val(),
			error: (model, error) => console.error error


	_performSaveDescriptionRequest: (event) =>
		console.log '>> Need to submit repository description change!'


	_clearErrors: () =>
		@$('.prettyFormErrorText').removeClass 'visible'


	_showErrors: (errors) =>
		@_clearErrors()

		for errorType, errorText of errors
			errorField = @$(".prettyFormErrorText[type='#{errorType}']")
			errorField.addClass 'visible'
			errorField.html errorText
