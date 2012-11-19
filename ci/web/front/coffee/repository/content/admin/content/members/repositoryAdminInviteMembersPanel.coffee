window.RepositoryAdminInviteMembersPanel = {}


class RepositoryAdminInviteMembersPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null

	initialize: () ->


class RepositoryAdminInviteMembersPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminInviteMembersPanel'
	template: Handlebars.compile '<div class="inviteForm">
			<input type="text" class="inviteMembersField" placeholder="emails"><button class="inviteButton">Invite</button>
		</div>
		<div class="inviteMembersHint">Seperate multiple email addresses with commas</div>'
	# events: 
	# 	'keyup': '_handleFormEntryChange'
	# 	'blur .prettyFormValue': '_handleSubmitChange'

	initialize: () =>

	render: () =>
		@$el.html @template()
		return @


	# _handleFormEntryChange: () =>
	# 	@model.set 'description', @$el.find('.repositoryDescriptionField').val()


	# _handleSubmitChange: (event) =>
	# 	console.log 'Need to submit repository change!'

	# 	errors = {}
	# 	@_displayErrors errors
	# 	@_showCorrectSavedMessage($(event.target)) if not errors? or Object.keys(errors).length is 0


	# _showCorrectSavedMessage: (field) =>
	# 	@$el.find('.repositoryDescriptionSavedText').css 'visibility', 'hidden'

	# 	if field.hasClass 'repositoryDescriptionField'
	# 		@$el.find('.repositoryDescriptionSavedText').css 'visibility', 'visible'


	# _clearErrors: () =>
	# 	@_displayErrors {}


	# _displayErrors: (errors = {}) =>
	# 	repositoryDescriptionError = @$el.find('.repositoryDescriptionErrorText')
	# 	@_displayErrorForField repositoryDescriptionError, errors.description


	# _displayErrorForField: (errorView, errorText) =>
	# 	if errorText?
	# 		errorView.text errorText
	# 		errorView.show()
	# 	else
	# 		errorView.text ''
	# 		errorView.hide()
