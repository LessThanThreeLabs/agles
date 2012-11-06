window.RepositoryHeaderOption = {}


class RepositoryHeaderOption.Model extends Backbone.Model
	defaults:
		repositories: null
		visible: true

	initialize: () ->
		window.globalAccount.on 'change:firstName change:lastName', () =>
			console.log 'user logged in -- need to update repositories'
			@set 'repositories', ['Repository #1', 'Repository #2', 'Repository #3']


class RepositoryHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderOption headerMenuOption'
	template: Handlebars.compile '<div class="dropdown">
			<span class="dropdown-toggle" data-toggle="dropdown" href="#">Repositories</span>
			<ul class="dropdown-menu dropdownContents pull-right" role="menu"></ul>
		</div>'
	dropdownContentsTemplate: Handlebars.compile '{{#each repositories}}
			<li><a href="#">{{this}}</a></li>
		{{/each}}
		{{#if repositories}}
			<li class="divider"></li>
		{{/if}}
		<li><a href="/repository/create">Create repository</a></li>'

	initialize: () ->
		@model.on 'change:repositories', () =>
			@_updateDropdownContents()
		@model.on 'change:visible', () =>
			@_fixVisibility()


	render: () ->
		@$el.html @template()
		@_updateDropdownContents()
		return @


	_updateDropdownContents: () =>
		@$el.find('.dropdownContents').html @dropdownContentsTemplate
			repositories: @model.get 'repositories'


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'
