'use strict'

describe 'Koality services', () ->

	describe 'initial state', () ->

		it 'should start a model server', () ->
			exec 'ls', (error, stdout, stderr) ->
				dump stdout

				expect(true).toBe false

