window.RepositoryHeaderOption = {}


class RepositoryHeaderOption.Model extends Backbone.Model
	defaults:
		repositories: null
		visible: true

	initialize: () ->
		window.globalAccount.on 'change:firstName change:lastName', () =>
			console.log 'user logged in -- need to update repositories'
			@set 'repositories', [
				{name: 'Repository #1', id: 17}, 
				{name: 'Repository #2', id: 18}, 
				{name: 'Repository #3', id: 19}
			]

class RepositoryHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderOption headerMenuOption'
	template: Handlebars.compile '<div class="dropdown">
			<span class="dropdown-toggle" data-toggle="dropdown" href="#">Repositories</span>
			<ul class="dropdown-menu dropdownContents pull-right" role="menu"></ul>
		</div>'
	dropdownContentsTemplate: Handlebars.compile '{{#each repositories}}
			<li><a class="repository" repositoryId={{this.id}}>{{this.name}}</a></li>
		{{/each}}
		{{#if repositories}}
			<li class="divider"></li>
		{{/if}}
		<li><a href="/repository/create">Create repository</a></li>'
	events:
		'click .repository': '_handleSelection'

	initialize: () ->
		@router = new Backbone.Router()

		@model.on 'change:repositories', () =>
			@_updateDropdownContents()
		@model.on 'change:visible', () =>
			@_fixVisibility()


	render: () ->
		@$el.html @template()
		@_updateDropdownContents()
		return @


	_handleSelection: (event) =>
		repositoryId = $(event.target).attr 'repositoryId'
		assert.ok repositoryId?

		@router.navigate 'repository/' + repositoryId, trigger: true


	_updateDropdownContents: () =>
		@$el.find('.dropdownContents').html @dropdownContentsTemplate
			repositories: @model.get 'repositories'


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'
