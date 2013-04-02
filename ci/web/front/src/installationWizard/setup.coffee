'use strict'

angular.module('koalitySetup', ['ngSanitize', 'koality.service', 'koality.directive', 'koality.filter']).
	config(['$routeProvider', ($routeProvider) ->
		$routeProvider.
			when('/wizard',
				templateUrl: "/html/installationWizard/wizard#{fileSuffix}.html"
				controller: Wizard
				reloadOnSearch: false
			).
			when('/unexpectedError',
				templateUrl: "/html/unexpectedError#{fileSuffix}.html"
				controller: UnexpectedError
			).
			when('/invalidPermissions',
				templateUrl: "/html/invalidPermissions#{fileSuffix}.html"
				controller: InvalidPermissions
			).
			otherwise(
				redirectTo: '/wizard'
			)
	]).
	config(['$locationProvider', ($locationProvider) ->
		$locationProvider.html5Mode true
	]).
	run(() ->
		# initialization happens here
	)
