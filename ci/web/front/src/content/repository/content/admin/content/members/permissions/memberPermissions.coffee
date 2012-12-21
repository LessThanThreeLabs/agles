window.MemberPermissions = {}


class MemberPermissions.Model extends Backbone.Model
	ALLOWED_PERMISSIONS: ['r', 'r/w', 'r/w/a']
	defaults:
		email: null
		firstName: null
		lastName: null
		permissions: null


	initialize: () =>
		@on 'change:permissions', @_submitPermissions


	validate: (attributes) =>
		if typeof attributes.email isnt 'string' or attributes.email is ''
			return new Error 'Invalid email: ' + attributes.email

		if typeof attributes.firstName isnt 'string' or attributes.firstName is ''
			return new Error 'Invalid first name: ' + attributes.firstName

		if typeof attributes.lastName isnt 'string' or attributes.lastName is ''
			return new Error 'Invalid last name: ' + attributes.lastName

		if attributes.permissions not in @ALLOWED_PERMISSIONS
			return new Error 'Invalid member permissions'

		return


	_submitPermissions: () =>
		console.log 'should pass a user id instead of an email address...'
		console.log 'is this firing when it shouldnt?....'
		
		requestData =
			method: 'changeMemberPermissions'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
				email: @get 'email'
				permissions: @get 'permissions'

		socket.emit 'repos:update', requestData, (errors, result) =>
			if errors?
				globalRouterModel.set 'view', 'invalidRepositoryState' if errors is 403
				console.error errors


	removeMember: () =>
		requestData =
			method: 'removeMember'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'
				email: @get 'email'

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


	onDispose: () =>


	render: () =>
		@$el.html @template
			email: @model.get 'email'
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
		@_selectCorrectPermissionsRadio()
		return @


	_selectCorrectPermissionsRadio: () =>
		permissions = @model.get('permissions')
		@$("input:radio[value='#{permissions}']").prop 'checked', true


	_handlePermissionsChange: (event) =>
		permissions = $(event.target).val()
		@model.set 'permissions', permissions,
			error: (model, error) => console.error error


	_handleRemoveMember: () =>
		@model.removeMember()
