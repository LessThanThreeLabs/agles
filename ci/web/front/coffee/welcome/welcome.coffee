window.Welcome = {}


class Welcome.Model extends Backbone.Model
	initialize: () ->


class Welcome.View extends Backbone.View
	tagName: 'div'
	className: 'welcome'
	template: Handlebars.compile '<div class="welcomeContents">
			<div class="description">Tentacles!</div>
			<div>
				<img class="welcomeImage" src="/img/awesomeFace.png">
			</div>
		</div>'

	initialize: () ->

	render: () ->
		@$el.html @template()
		return @
