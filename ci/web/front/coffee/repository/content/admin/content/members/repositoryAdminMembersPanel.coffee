window.RepositoryAdminMembersPanel = {}


class RepositoryAdminMembersPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null

	initialize: () ->
		@inviteMembersPanelModel = new RepositoryAdminInviteMembersPanel.Model()


class RepositoryAdminMembersPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMembersPanel'
	template: Handlebars.compile '<div class="inviteMembers">
			<div class="inviteMembersTitle">Invite Members</div>
			<div class="inviteMembersContent"></div>
		</div>'
	# events: 
	# 	'keyup': '_handleFormEntryChange'
	# 	'blur .prettyFormValue': '_handleSubmitChange'

	initialize: () =>

	render: () =>
		@$el.html @template()

		inviteMembersPanelView = new RepositoryAdminInviteMembersPanel.View model: @model.inviteMembersPanelModel
		@$el.find('.inviteMembersContent').html inviteMembersPanelView.render().el

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
