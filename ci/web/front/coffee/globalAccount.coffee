class GlobalAccount extends Backbone.Model
	defaults:
		firstName: ''
		lastName: ''
		image: null

	initialize: () =>


	validate: () =>
		return


# !!!! SINGLETON !!!!
window.globalAccount = new GlobalAccount()