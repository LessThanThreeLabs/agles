window.CreateRepository = {}


class CreateRepository.Model extends Backbone.Model
	ALLOWED_PERMISSIONS: ['read', 'write', 'admin']
	defaults:
		name: ''
		description: ''
		defaultPermissions: 'write'

	initialize: () =>


class CreateRepository.View extends Backbone.View
	tagName: 'div'
	className: 'createRepository'
	template: Handlebars.compile '<div class="createRepositoryInformation">
			Specify the details of your repository.
		</div>
		<div class="prettyForm createRepositoryForm">
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Name
				</div>
				<div class="prettyFormValue">
					<input type="text" class="repositoryNameField" placeholder="name" maxlength=32>
					<div class="prettyFormErrorText repositoryNameErrorText"></div>
				</div>
			</div>
			<div class="prettyFormEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Description
				</div>
				<div class="prettyFormValue">
					<textarea type="text" class="repositoryDescriptionField" placeholder="description" maxlength=256></textarea>
					<div class="prettyFormErrorText repositoryDescriptionErrorText"></div>
				</div>
			</div>
			<div class="prettyFormEmptyRow"></div>
			<div class="prettyFormRow">
				<div class="prettyFormLabel">
					Default permissions
				</div>
				<div class="prettyFormValue">
					<div class="btn-group" data-toggle="buttons-radio">
						<button class="btn defaultPermissionsOption readPermissionsOption" type="read">Read</button>
						<button class="btn defaultPermissionsOption writePermissionsOption" type="write">Write</button>
						<button class="btn defaultPermissionsOption adminPermissionsOption" type="admin">Admin</button>
					</div>
				</div>
			</div>
		</div>
		<div class="createRepositoryButtonContainer">
			<button class="btn createRepositoryButton">Create Repository</button>
		</div>'
	events: 
		'keyup': '_handleFormEntryChange'
		'click .defaultPermissionsOption': '_handleDefaultPermissionsSelection'
		'click .createRepositoryButton': '_handleCreateRepository'

	initialize: () =>
		@router = new Backbone.Router()


	render: () =>
		@$el.html @template()

		@$el.find('.repositoryNameField').val @model.get 'name'
		@$el.find('.repositoryDescriptionField').val @model.get 'description'
		@$el.find('.defaultPermissionsOption[type=' + @model.get('defaultPermissions') + ']').addClass 'active'

		return @


	_handleFormEntryChange: () =>
		@model.set 'name', @$el.find('.repositoryNameField').val()
		@model.set 'description', @$el.find('.repositoryDescriptionField').val()


	_handleDefaultPermissionsSelection: (event) =>
		type = $(event.target).attr 'type'
		@model.set 'defaultPermissions', type


	_handleCreateRepository: () =>
		requestData =
			name: @model.get 'name'
			description: @model.get 'description'
			defaultPermissions: @model.get 'defaultPermissions'
		
		console.log 'need to make request with:'
		console.log requestData
		console.log 'checking of these fields needs to be done on the webserver...'

		# socket.emit 'repositories:create', requestData, (errors, repository) =>
		# 	console.log 'navigate page to repository ' + repository.id
		repository = id: 17
		@router.navigate 'repository/' + repository.id, trigger: true


	_clearErrors: () =>
		@_displayErrors {}


	_displayErrors: (errors = {}) =>
		nameError = @$el.find('.repositoryNameErrorText')
		descriptionError = @$el.find('.repositoryDescriptionErrorText')

		@_displayErrorForField nameError, errors.name
		@_displayErrorForField descriptionError, errors.description


	_displayErrorForField: (errorView, errorText) =>
		if errorText?
			errorView.text errorText
			errorView.show()
		else
			errorView.text ''
			errorView.hide()
			