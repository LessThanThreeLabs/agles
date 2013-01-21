window.AccountCurrentSshKeysPanel = {}


class AccountCurrentSshKeysPanel.Model extends Backbone.Model
	subscribeUrl: 'users'
	subscribeId: null


	initialize: () =>
		@subscribeId = globalAccount.get 'userId'

		@sshKeyRowModels = new Backbone.Collection()
		@sshKeyRowModels.model = AccountSshKeysRow.Model
		@sshKeyRowModels.comparator = (sshKeyRowModel) =>
			return sshKeyRowModel.get 'alias'


	fetchKeys: () =>
		@sshKeyRowModels.reset()

		requestData =
			method: 'getSshKeys'
			args: {}

		socket.emit 'users:read', requestData, (error, sshKeys) =>
			if error?
				console.error error
			else
				@sshKeyRowModels.reset sshKeys, error: (model, error) => console.error error


	onUpdate: (data) =>
		if data.type is 'ssh pubkey added'
			sshKeyRowModel = new AccountSshKeysRow.Model
				alias: data.contents.alias
				dateAdded: data.contents.dateAdded
			@sshKeyRowModels.add sshKeyRowModel
		else if data.type is 'ssh pubkey removed'
			assert.ok data.contents.alias
			@sshKeyRowModels.remove @sshKeyRowModels.where alias: data.contents.alias


class AccountCurrentSshKeysPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountCurrentSshKeysPanel'
	html: '<div class="prettyTable sshKeysTable">
			<div class="prettyTableTitleRow">
				<div class="prettyTableColumn aliasColumn">Alias</div>
				<div class="prettyTableColumn createdDateColumn">Created</div>
				<div class="prettyTableColumn removeKeyColumn">Remove</div>
			</div>
		</div>'


	initialize: () =>
		@model.sshKeyRowModels.on 'add', @_handleAdd, @
		@model.sshKeyRowModels.on 'reset', @render, @

		# TODO: make this smarter... (like handleAdd)
		@model.sshKeyRowModels.on 'remove', @render, @

		@model.subscribe()
		@model.fetchKeys()


	onDispose: () =>
		@model.unsubscribe()
		@model.sshKeyRowModels.off null, null, @


	render: () =>
		@$el.html @html
		@_addCurrentKeys()
		return @


	_addCurrentKeys: () =>
		@model.sshKeyRowModels.each (sshKeyRowModel) =>
			sshKeyRowView = new AccountSshKeysRow.View model: sshKeyRowModel
			@$('.sshKeysTable').append sshKeyRowView.render().el


	_handleAdd: (sshKeyRowModel, collection, options) =>
		sshKeyRowView = new AccountSshKeysRow.View model: sshKeyRowModel
		@_insertSshKeyAtIndex sshKeyRowView.render().el, options.index


	_insertSshKeyAtIndex: (sshKeyRowView, index) =>
		if index is 0
			@$el.find('.sshKeysTable').append sshKeyRowView
		else
			@$el.find('.sshKeysTable .accountSshKeysRow:nth-child('+ (index+1) + ')').after sshKeyRowView
