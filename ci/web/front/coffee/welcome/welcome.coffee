window.Welcome = {}


class Welcome.Model extends Backbone.Model
	

class Welcome.View extends Backbone.View
	tagName: 'div'
	className: 'welcome'
	html: '<div class="welcomeContents">
				<div class="description">Hello!</div>
				<div><img class="welcomeImage" src="/img/awesomeFace.png"></div>
			</div>'


	render: () =>
		@$el.html @html
		return @
