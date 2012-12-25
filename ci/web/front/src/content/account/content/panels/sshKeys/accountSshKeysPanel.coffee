window.AccountSshKeysPanel = {}


class AccountSshKeysPanel.Model extends Backbone.Model

	initialize: () =>
		@currentSshKeysPanelModel = new AccountCurrentSshKeysPanel.Model()
		@addSshKeyPanelModel = new AccountAddSshKeyPanel.Model()
		@modalModel = new PrettyModal.Model()


class AccountSshKeysPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountSshKeysPanel'
	html: '<div class="currentKeysContainer">
			<div class="currentKeysTitle">Current Keys</div>
			<div class="currentKeysContent"></div>
		</div>
		<div class="addSshKeyContainer">
			<button class="addSshKeyButton">Add Key</button>
		</div>'
	events: 'click .addSshKeyButton': '_handleAddSshKey'


	initialize: () =>
		@currentSshKeysPanelView = new AccountCurrentSshKeysPanel.View model: @model.currentSshKeysPanelModel
		@addSshKeyPanelView = new AccountAddSshKeyPanel.View model: @model.addSshKeyPanelModel
		@modalView = new PrettyModal.View model: @model.modalModel

		@model.modalModel.on 'change:visible', @_handleModalVisibilityChange, @

		@addSshKeyPanelView.on 'addedKey', () =>
			@model.modalModel.set 'visible', false


	onDispose: () =>
		@currentSshKeysPanelView.dispose()
		@addSshKeyPanelView.dispose()
		@modalView.dispose()


	render: () =>
		@$el.html @html
		@$('.currentKeysContent').html @currentSshKeysPanelView.render().el
		@$el.append @modalView.render().el
		@modalView.setInnerHtml @addSshKeyPanelView.render().el
		return @


	_handleAddSshKey: () =>
		@model.modalModel.set 'visible', true,
			error: (model, error) => console.error error


	_handleModalVisibilityChange: () =>
		if @model.modalModel.get 'visible'
			@addSshKeyPanelView.correctFocus()
		else
			@model.addSshKeyPanelModel.reset()
