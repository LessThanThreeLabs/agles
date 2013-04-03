'use strict'

describe 'Koality filters', () ->

	describe 'fileSuffix filter', () ->
		fileSuffix = null
		suffixString = '_qa8aset32'

		beforeEach module 'koality.filter', ($provide) ->
			mockedInitialState = fileSuffix: suffixString
			$provide.value 'initialState', mockedInitialState
			return

		beforeEach () ->
			inject (fileSuffixFilter) ->
				fileSuffix = fileSuffixFilter

		it 'should correctly add file suffix for valid file urls', () ->
			expect(fileSuffix 'hello.png').toBe "hello#{suffixString}.png"
			expect(fileSuffix 'hello/there.jpg').toBe "hello/there#{suffixString}.jpg"
			expect(fileSuffix '/hello/there/sir.gif').toBe "/hello/there/sir#{suffixString}.gif"

		it 'should fail to add the correct file suffix for invalid file urls', () ->
			expect(fileSuffix 'hellopng').toBe 'hellopng'
			expect(fileSuffix 'hello/therejpg').toBe 'hello/therejpg'
			expect(fileSuffix '/hello/there/sirgif').toBe '/hello/there/sirgif'

	describe 'newLine filter', () ->
		beforeEach module 'koality.filter'

		it 'should handle invalid values', () ->
			inject (newLineFilter) ->
				expect(newLineFilter null).toBe null
				expect(newLineFilter 15).toBe null
				expect(newLineFilter 15.1).toBe null
				expect(newLineFilter {}).toBe null

		it 'should not change strings without new lines', () ->
			inject (newLineFilter) ->
				expect(newLineFilter '').toBe ''
				expect(newLineFilter 'hello').toBe 'hello'
				expect(newLineFilter 'hello there').toBe 'hello there'
				expect(newLineFilter ' hello').toBe ' hello'
				expect(newLineFilter 'hello ').toBe 'hello '

		it 'should add <br>\'s correctly', () ->
			inject (newLineFilter) ->
				expect(newLineFilter '\n').toBe '<br>'
				expect(newLineFilter 'hello\n').toBe 'hello<br>'
				expect(newLineFilter '\nhello').toBe '<br>hello'
				expect(newLineFilter 'hello\nthere').toBe 'hello<br>there'
				expect(newLineFilter '\nhello\nthere').toBe '<br>hello<br>there'
				expect(newLineFilter '\nhello\nthere\n').toBe '<br>hello<br>there<br>'
