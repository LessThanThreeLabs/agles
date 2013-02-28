'use strict'

describe 'Koality filters', () ->

	describe 'ansiparse filter', () ->
		ansiparse = null

		beforeEach module 'koality.filter'

		beforeEach () ->
			inject (ansiparseFilter) ->
				ansiparse = ansiparseFilter

		it 'should wrap plaintext in default styling', () ->
			expect(ansiparse 'thisIsATest').toBe '<span class="ansi"><span class="foregroundDefault backgroundDefault">thisIsATest</span></span>'

		it 'should escape spaces', () ->
			expect(ansiparse 'this is  A   test').toBe '<span class="ansi"><span class="foregroundDefault backgroundDefault">this&nbspis&nbsp&nbspA&nbsp&nbsp&nbsptest</span></span>'

		it 'should handle changing columns', () ->
			expect(ansiparse 'one\x1b[5Gtwo').toBe '<span class="ansi"><span class="foregroundDefault backgroundDefault">one&nbsp&nbsptwo</span></span>'
			expect(ansiparse 'one\x1b[0Gtwo').toBe '<span class="ansi"><span class="foregroundDefault backgroundDefault">two</span></span>'

		it 'should handle colors, bold, and clearing', () ->
			expect(ansiparse '\x1b[33;45;1mbright yellow on magenta, \x1b[0mdefault').toBe '<span class="ansi"><span class="foregroundYellow backgroundMagenta bright">bright&nbspyellow&nbspon&nbspmagenta,&nbsp</span>' +
				'<span class="foregroundDefault backgroundDefault">default</span></span>'

		it 'should persist colors and bold through other styles', () ->
			expect(ansiparse 'default, \x1b[31;1mbright red, \x1b[34;46mbright blue on cyan, \x1b[22mblue on cyan')
				.toBe '<span class="ansi"><span class="foregroundDefault backgroundDefault">default,&nbsp</span>' +
					'<span class="foregroundRed backgroundDefault bright">bright&nbspred,&nbsp</span>' +
					'<span class="foregroundBlue backgroundCyan bright">bright&nbspblue&nbspon&nbspcyan,&nbsp</span>' +
					'<span class="foregroundBlue backgroundCyan">blue&nbspon&nbspcyan</span></span>'

		it 'should overwrite old characters with new styles', () ->
			expect(ansiparse 'plain\x1b[0G\x1b[32mgreen').toBe '<span class="ansi"><span class="foregroundGreen backgroundDefault">green</span></span>'

		it 'should handle carriage returns', () ->
			expect(ansiparse 'originalString\rnewString').toBe '<span class="ansi"><span class="foregroundDefault backgroundDefault">newString</span></span>'

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

