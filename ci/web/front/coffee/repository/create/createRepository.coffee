window.CreateRepository = {}


class CreateRepository.Model extends Backbone.Model
	ALLOWED_PERMISSIONS: ['read', 'write', 'admin']
	defaults:
		name: null
		description: null
		defaultPermissions: null

	initialize: () =>
		@on 'change:name', () =>
			console.log 'name: ' + @get 'name'
		@on 'change:description', () =>
			console.log 'description ' + @get 'description'


class CreateRepository.View extends Backbone.View
	tagName: 'div'
	className: 'createRepository'
	template: Handlebars.compile '<div class="createRepositoryInformation">
			Specify the details of your repository.
		</div>
		<div class="createRepositoryForm">
			<div class="createRepositoryRow">
				<div class="createRepositoryLabel">
					Name
				</div>
				<div class="createRepositoryValue">
					<input type="text" class="repositoryNameField" placeholder="name" maxlength=32>
				</div>
			</div>
			<div class="createRepositoryEmptyRow"></div>
			<div class="createRepositoryRow">
				<div class="createRepositoryLabel">
					Description
				</div>
				<div class="createRepositoryValue">
					<textarea type="text" class="repositoryDescriptionField" placeholder="description" maxlength=256></textarea>
				</div>
			</div>
			<div class="createRepositoryEmptyRow"></div>
			<div class="createRepositoryRow">
				<div class="createRepositoryLabel">
					Default permissions
				</div>
				<div class="createRepositoryValue">
					<div class="btn-group" data-toggle="buttons-radio">
						<button class="btn">Read</button>
						<button class="btn">Write</button>
						<button class="btn">Admin</button>
					</div>
				</div>
			</div>
		</div>
		<div class="createRepositoryButtonContainer">
			<button class="btn createRepositoryButton">Create Repository</button>
		</div>'
	events: 
		'keyup': '_handleFormEntryChange'
		# 'change .loginRememberMe': '_handleFormEntryChange'
		'click .createRepositoryButton': '_handleCreateRepository'

	initialize: () =>


	render: () =>
		@$el.html @template()
		return @


	_handleFormEntryChange: () =>
		@model.set 'name', @$el.find('.repositoryNameField').val()
		@model.set 'description', @$el.find('.repositoryDescriptionField').val()
		console.log 'need to also update the default permissions'


	_handleCreateRepository: () =>
		console.log 'need to create the repository'