window.RepositoryAdminMemberPermissionsPanel = {}


class RepositoryAdminMemberPermissionsPanel.Model extends Backbone.Model
	defaults:
		repositoryId: null
		# will need users here...


class RepositoryAdminMemberPermissionsPanel.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminMemberPermissionsPanel'
	template: Handlebars.compile 'hello'

	initialize: () =>

	render: () =>
		@$el.html @template()
		return @
