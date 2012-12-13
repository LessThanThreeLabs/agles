window.MemberPermissions = {}


class MemberPermissions.Model extends Backbone.Model
	ALLOWED_PERMISSIONS: ['r', 'r/w', 'r/w/a']

	defaults:
		email: null
		firstName: null
		lastName: null
		permissions: null


	validate: (attributes) =>
		if attributes.permissions not in @ALLOWED_PERMISSIONS
			return new Error 'Invalid member permissions'
		return


	_changePermissions: (permissions, callback) =>
		email = @get 'email'

		requestData =
			method: 'changeMemberPermissions'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
				email: email
				permissions: permissions

		socket.emit 'repos:update', requestData, (errors, result) =>
			if errors?
				globalRouterModel.set 'view', 'invalidRepositoryState' if errors is 403
				callback errors
			else
				@set 'permissions', permissions
				callback null, null


	_removeMember: () =>
		email = @get 'email'

		requestData =
			method: 'removeMember'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
				email: email

		socket.emit 'repos:update', requestData, (errors, result) =>
			if errors?
				globalRouterModel.set 'view', 'invalidRepositoryState' if errors is 403
				console.error errors


class MemberPermissions.View extends Backbone.View
	tagName: 'div'
	className: 'memberPermissions prettyTableRow'
	template: Handlebars.compile '
		<div class="prettyTableColumn">{{email}}</div>
		<div class="prettyTableColumn">{{firstName}}</div>
		<div class="prettyTableColumn">{{lastName}}</div>
		<div class="prettyTableColumn permissionsRadio readPermissionColumn"><input type="radio" value="r" name="{{email}}PermissionsRadio"></div>
		<div class="prettyTableColumn permissionsRadio readWritePermissionColumn"><input type="radio" value="r/w" name="{{email}}PermissionsRadio"></div>
		<div class="prettyTableColumn permissionsRadio readWriteAdminPermissionColumn"><input type="radio" value="r/w/a" name="{{email}}PermissionsRadio"></div>
		<div class="prettyTableColumn removeMemberColumn"><img src="/img/icons/removeMember.svg" class="removeMemberImage"></div>'
	events:
		'change .permissionsRadio': '_handlePermissionsChange'
		'click .removeMemberImage': '_handleRemoveMember'


	initialize: () =>
		@model.on 'change:permissions', @_selectCorrectPermissionsRadio, @


	onDispose: () =>


	render: () =>
		@$el.html @template
			email: @model.get 'email'
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
		@_selectCorrectPermissionsRadio()
		return @


	_selectCorrectPermissionsRadio: () =>
		@$el.find('input:radio[value="' + @model.get('permissions') + '"]').prop 'checked', true


	_handlePermissionsChange: (event) =>
		permissions = $(event.target).val()
		@model._changePermissions permissions, (error, result) =>
			@_selectCorrectPermissionsRadio() if errors?

	_handleRemoveMember: () =>
		@model._removeMember()
