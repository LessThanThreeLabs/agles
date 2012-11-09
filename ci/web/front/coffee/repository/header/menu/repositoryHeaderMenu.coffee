window.RepositoryHeaderMenu = {}


class RepositoryHeaderMenu.Model extends Backbone.Model
	# default:
	# 	url: null

	initialize: () =>

	# validate: (attributes) =>
	# 	if not attributes.url? or attributes.url.length is 0
	# 		return new Error 'Invalid repository url'

	# 	return


class RepositoryHeaderMenu.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryHeaderMenu'
	template: Handlebars.compile '<div class="repositoryHeaderMenuOptions">
			<div class="blankRepositoryMenuOption"></div>
			<div class="repositoryMenuOption"></div>
			<div class="repositoryMenuOption"></div>
		</div>'

	initialize: () =>
		# @model.on 'change:url', @render


	render: () =>
		@$el.html @template()
		return @
