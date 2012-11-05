window.RepositoryHeaderOption = {}


class RepositoryHeaderOption.Model extends Backbone.Model
	defaults:
		visible: true

	initialize: () ->
		window.globalAccount.on 'change:firstName change:lastName', () =>
			console.log 'user logged in -- need to update repositories'


class RepositoryHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderOption headerMenuOption'
	template: Handlebars.compile '<div class="dropdown">
			<span class="dropdown-toggle" data-toggle="dropdown" href="#">Repositories</span>
			<ul class="dropdown-menu" role="menu">
				<li><a tabindex="-1" href="#">Repository #1</a></li>
				<li><a tabindex="-1" href="#">Repository #2</a></li>
				<li><a tabindex="-1" href="#">Repository #3</a></li>
				<li class="divider"></li>
				<li><a tabindex="-1" href="#">More options</a></li>
			</ul>
		</div>'

	# events: 'click': '_clickHandler'


	initialize: () ->
		@model.on 'change:visible', () =>
			@_fixVisibility()


	render: () ->
		@$el.html @template()
		return @


	_clickHandler: () =>
		console.log 'clicked'
		@trigger 'repositorySelected', 17


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'
