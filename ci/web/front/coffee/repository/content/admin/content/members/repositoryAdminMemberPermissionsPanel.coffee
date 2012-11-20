window.RepositoryAdminMemberPermissionsPanel = {}


class RepositoryAdminMemberPermissionsPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null
		# will need users here...

	initialize: () =>
		@memberPermissionsModels = new Backbone.Collection()
		@memberPermissionsModels.model = MemberPermissions.Model
		@memberPermissionsModels.comparator = (memberPermissionsModel) =>
			return memberPermissionsModel.get 'email'


	fetchMembersIfNecassary: () =>
		# DON'T FETCH MEMBERS IF MEMBERS HAVE BEEN FETCHED BEFORE!!!!
		console.log 'need to fetch members'

		member1 =
			email: 'fake@email.com'
			firstName: 'fake'
			lastName: 'email'
			permissions: 'r'
		member2 =
			email: 'fake@email2.com'
			firstName: 'faker'
			lastName: 'email'
			permissions: 'r/w'

		@memberPermissionsModels.add [member1, member2]


class RepositoryAdminMemberPermissionsPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMemberPermissionsPanel'
	template: Handlebars.compile '<div class="prettyTable>
			<div class="prettyTableTitleRow">
				<!-- stuff here... -->
			</div>
			<div class="memberPermissionsRows"></div>
		</div>'

	initialize: () =>
		@model.memberPermissionsModels.on 'add', (memberPermissionsModel, collection, options) =>
			memberPermissionView = new MemberPermissions.View model: memberPermissionsModel
			@_insertBuildAtIndex memberPermissionView.render().el, options.index
		@model.memberPermissionsModels.on 'reset', () =>
			@$el.html @template()


	render: () =>
		@$el.html @template()
		@model.fetchMembersIfNecassary()
		return @


	_insertBuildAtIndex: (memberPermissionView, index) =>
		console.log 'repo admin member permission panel -- this is all wrong...'
		if index == 0 
			@$el.find('.memberPermissionsRows').prepend memberPermissionView
		else
			@$el.find('.memberPermissionsRows .memberPermissions:nth-child('+ index + ')').after memberPermissionView
