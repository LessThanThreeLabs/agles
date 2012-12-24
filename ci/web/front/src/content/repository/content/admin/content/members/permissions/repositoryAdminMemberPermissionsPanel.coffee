window.RepositoryAdminMemberPermissionsPanel = {}


class RepositoryAdminMemberPermissionsPanel.Model extends Backbone.Model
	subscribeUrl: 'repos'
	subscribeId: null

	initialize: () =>
		@subscribeId = globalRouterModel.get 'repositoryId'

		@memberPermissionsModels = new Backbone.Collection()
		@memberPermissionsModels.model = MemberPermissions.Model
		@memberPermissionsModels.comparator = (memberPermissionsModel) =>
			return memberPermissionsModel.get 'email'


	fetchMembers: () =>
		@memberPermissionsModels.reset()

		requestData =
			method: 'getMembersWithPermissions'
			args:
				repositoryId: globalRouterModel.get 'repositoryId'

		socket.emit 'repos:read', requestData, (errors, users) =>
			if errors?
				globalRouterModel.set 'view', 'invalidRepositoryState' if errors is 403
				console.error errors
			else
				@memberPermissionsModels.reset users,
					error: (model, error) => console.error error


	onUpdate: (data) =>
		assert.ok data.type?

		switch data.type
			when 'member added'
				assert.ok data.contents.email? and data.contents.firstName? and
					data.contents.lastName? and data.contents.permissions?
				memberPermissionsModel = new MemberPermissions.Model data.contents
				@memberPermissionsModels.add memberPermissionsModel
			when 'member removed'
				assert.ok data.contents.email?
				@memberPermissionsModels.remove @memberPermissionsModels.where email: data.contents.email
			when 'member permissions changed'
				assert.ok data.contents.email? and data.contents.permissions?
				@memberPermissionsModels.where(email: data.contents.email)[0].set 'permissions', data.contents.permissions
			else
				console.error 'Unaccounted for update type: ' + data.type


class RepositoryAdminMemberPermissionsPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMemberPermissionsPanel'
	html: '<div class="prettyTable permissionsTable">
			<div class="prettyTableTitleRow">
				<div class="prettyTableColumn">Email</div>
				<div class="prettyTableColumn">First Name</div>
				<div class="prettyTableColumn">Last Name</div>
				<div class="prettyTableColumn readPermissionColumn">R</div>
				<div class="prettyTableColumn readWritePermissionColumn">R/W</div>
				<div class="prettyTableColumn readWriteAdminPermissionColumn">R/W/A</div>
				<div class="prettyTableColumn removeMemberColumn">Remove</div>
			</div>
		</div>'


	initialize: () =>
		@model.memberPermissionsModels.on 'add', @_handleAdd, @
		@model.memberPermissionsModels.on 'reset', @render, @

		# TODO: make this smarter... (like handleAdd)
		@model.memberPermissionsModels.on 'remove', @render, @

		@model.subscribe()
		@model.fetchMembers()


	onDispose: () =>
		@model.unsubscribe()
		@model.memberPermissionsModels.off null, null, @


	render: () =>
		@$el.html @html
		@_addCurrentMembers()
		return @


	_addCurrentMembers: () =>
		@model.memberPermissionsModels.each (memberPermissionsModel) =>
			memberPermissionView = new MemberPermissions.View model: memberPermissionsModel
			@$('.permissionsTable').append memberPermissionView.render().el


	_handleAdd: (memberPermissionsModel, collection, options) =>
		memberPermissionView = new MemberPermissions.View model: memberPermissionsModel
		@_insertMemberAtIndex memberPermissionView.render().el, options.index


	_insertMemberAtIndex: (memberPermissionView, index) =>
		memberPermissionRowsOffset = 2
		console.log 'do not think this variable is ever used...'

		if index is 0
			@$el.find('.permissionsTable').append memberPermissionView
		else
			@$el.find('.permissionsTable .memberPermissions:nth-child('+ (index+1) + ')').after memberPermissionView

