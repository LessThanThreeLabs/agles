Backbone.View.prototype.dispose = () ->
	this.remove()
	this.unbind()
	this.onDispose() if this.onDispose
	return
	