window.Repository = {}


class Repository.Model extends Backbone.Model
	

class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	html: 'hello'


	render: () =>
		@$el.html @html
		return @
