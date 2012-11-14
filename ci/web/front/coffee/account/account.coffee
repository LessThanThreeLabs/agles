window.Account = {}


class Account.Model extends Backbone.Model
	defaults:
		firstName: null
		lastName: null
		image: null

	initialize: () ->
		@set 'firstName', window.globalAccount.get 'firstName'
		@set 'lastName', window.globalAccount.get 'lastName'
		@set 'image', window.globalAccount.get 'image'


class Account.View extends Backbone.View
	tagName: 'div'
	className: 'account'
	template: Handlebars.compile 'Account stuff here'
	# events: 
	# 	'keyup': '_handleFormEntryChange'
	# 	'click .defaultPermissionsOption': '_handleDefaultPermissionsSelection'
	# 	'click .createRepositoryButton': '_handleCreateRepository'

	initialize: () ->

	render: () ->
		@$el.html @template()
		return @
