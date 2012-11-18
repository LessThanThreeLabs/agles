window.RepositoryAdminGeneralPanel = {}


class RepositoryAdminGeneralPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null
		repositoryName: null
		repositoryDescription: null

	initialize: () ->


class RepositoryAdminGeneralPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminGeneralPanel'
	template: Handlebars.compile '</div>
		<div class="prettyForm generalAdminForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Description
				</div>
				<div class="prettyFormValue">
					<textarea type="text" class="repositoryDescriptionField" placeholder="description" maxlength=256></textarea><span class="prettyFormSaveText repositoryDescriptionSavedText">Saved</span>
					<div class="prettyFormErrorText repositoryDescriptionErrorText"></div>
				</div>
			</div>
		</div>'
	events: 
		'keyup': '_handleFormEntryChange'
		'blur .prettyFormValue': '_handleSubmitChange'

	initialize: () =>

	render: () =>
		@$el.html @template()
		return @


	_handleFormEntryChange: () =>
		@model.set 'description', @$el.find('.repositoryDescriptionField').val()


	_handleSubmitChange: (event) =>
		console.log 'Need to submit repository change!'

		errors = {}
		@_displayErrors errors
		@_showCorrectSavedMessage($(event.target)) if not errors? or Object.keys(errors).length is 0


	_showCorrectSavedMessage: (field) =>
		@$el.find('.repositoryDescriptionSavedText').css 'visibility', 'hidden'

		if field.hasClass 'repositoryDescriptionField'
			@$el.find('.repositoryDescriptionSavedText').css 'visibility', 'visible'


	_clearErrors: () =>
		@_displayErrors {}


	_displayErrors: (errors = {}) =>
		repositoryDescriptionError = @$el.find('.repositoryDescriptionErrorText')
		@_displayErrorForField repositoryDescriptionError, errors.description


	_displayErrorForField: (errorView, errorText) =>
		if errorText?
			errorView.text errorText
			errorView.show()
		else
			errorView.text ''
			errorView.hide()
