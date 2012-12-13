window.Welcome = {}


class Welcome.Model extends Backbone.Model
	

class Welcome.View extends Backbone.View
	tagName: 'div'
	className: 'welcome'
	html: '<div class="welcomeContents">
				<div class="description">
					(1) Always bind to events before anything else<br>
					(2) Remove bindings in onDispose()<br>
					(3) Make sure you call dispose() at the right times<br>
					(4) Check heap profiles when adding view logic
				</div>
				<div><img class="welcomeImage" src="/img/awesomeFace.png"></div>
			</div>'


	render: () =>
		@$el.html @html
		return @

