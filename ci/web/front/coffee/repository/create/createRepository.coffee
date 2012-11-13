window.CreateRepository = {}


class CreateRepository.Model extends Backbone.Model
	defaults:
		name: null
		description: null

	initialize: () =>


class CreateRepository.View extends Backbone.View
	tagName: 'div'
	className: 'createRepository'
	template: Handlebars.compile '<div class="createRepositoryForm">
			<div class="createRepositoryRow">
				<div class="createRepositoryLabel">
					Name
				</div>
				<div class="createRepositoryValue">
					<input type="text" class="repositoryNameField" placeholder="name" maxlength=32>
				</div>
			</div>
			<div class="createRepositoryRow">
				<div class="createRepositoryLabel">
					Description
				</div>
				<div class="createRepositoryValue">
					<textarea type="text" class="repositoryDescriptionField" placeholder="description" maxlength=256></textarea>
				</div>
			</div>
			<div class="createRepositoryRow">
				<div class="createRepositoryLabel">
					Default permissions
				</div>
				<div class="createRepositoryValue">
					Default permissions here
				</div>
			</div>
		</div>'

	initialize: () =>


	render: () =>
		@$el.html @template()
		return @
