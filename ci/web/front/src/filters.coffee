'use strict'

angular.module('koality.filter', ['koality.service']).
	filter('fileSuffix', ['fileSuffixAdder', (fileSuffixAdder) ->
		(input) ->
			return fileSuffixAdder.addFileSuffix input
	]).
	filter('newLine', [() ->
		(input) ->
			return null if not input? or typeof input isnt 'string'
			return input.replace /\n/g, '<br>'
	])
