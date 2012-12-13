window.InvalidRepositoryState = {}


class InvalidRepositoryState.Model extends Backbone.Model
	

class InvalidRepositoryState.View extends Backbone.View
	tagName: 'div'
	className: 'invalidRepositoryState'
	html: '<div class="contents">
				<div class="description">
					Sorry bro, but you tried to access something you were not allowed to see!
				</div>
				<div><img class="welcomeImage" src="/img/awesomeFace.png"></div>
			</div>'


	render: () =>
		@$el.html @html
		return @
