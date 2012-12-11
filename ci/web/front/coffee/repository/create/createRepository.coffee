window.CreateRepository = {}


class CreateRepository.Model extends Backbone.Model
	ALLOWED_PERMISSIONS: ['r', 'r/w', 'r/w/a']
	defaults:
		name: ''
		description: ''
		defaultPermissions: 'r/w'


class CreateRepository.View extends Backbone.View
	tagName: 'div'
	className: 'createRepository'
	html: '<div class="createRepositoryInformation">
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
						<button class="btn defaultPermissionsOption readPermissionsOption" type="r">Read</button>
						<button class="btn defaultPermissionsOption writePermissionsOption" type="r/w">Write</button>
						<button class="btn defaultPermissionsOption adminPermissionsOption" type="r/w/a">Admin</button>
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


	render: () =>
		@$el.html @html

		@$el.find('.repositoryNameField').val @model.get 'name'
		@$el.find('.repositoryDescriptionField').val @model.get 'description'
		@$el.find('.defaultPermissionsOption[type="' + @model.get('defaultPermissions') + '"]').addClass 'active'

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
		
		socket.emit 'repos:create', requestData, (errors, repositoryId) =>
			console.log 'navigate page to repository ' + repositoryId
			if errors?
				console.error "Failed to create repository"
				#TODO do something
			else
				attributesToSet = 
		            view: 'repository'
        		    repositoryId: repositoryId
        		globalRouterModel.set attributesToSet,error: (model, error) => console.error error


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
			