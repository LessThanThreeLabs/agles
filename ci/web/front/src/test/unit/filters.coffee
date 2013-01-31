'use strict'

describe 'Koality filters', () ->

	beforeEach module 'koality.filter'

	describe 'ansiparse', () ->

		ansiparse = null
		beforeEach () ->
			inject (ansiparseFilter) ->
				ansiparse = ansiparseFilter

		it 'should wrap plaintext in default styling', () ->
			expect(ansiparse 'thisIsATest').toBe '<span class="foregroundDefault backgroundDefault">thisIsATest</span>'

		it 'should escape spaces', () ->
			expect(ansiparse 'this is  A   test').toBe '<span class="foregroundDefault backgroundDefault">this&nbspis&nbsp&nbspA&nbsp&nbsp&nbsptest</span>'

		it 'should handle changing columns', () ->
			expect(ansiparse 'one\x1b[5Gtwo').toBe '<span class="foregroundDefault backgroundDefault">one&nbsp&nbsptwo</span>'
			expect(ansiparse 'one\x1b[0Gtwo').toBe '<span class="foregroundDefault backgroundDefault">two</span>'

		it 'should handle colors, bold, and clearing', () ->
			expect(ansiparse '\x1b[33;45;1mbright yellow on magenta, \x1b[0mdefault').toBe '<span class="foregroundYellow backgroundMagenta bright">bright&nbspyellow&nbspon&nbspmagenta,&nbsp</span>' +
				'<span class="foregroundDefault backgroundDefault">default</span>'

		it 'should persist colors and bold through other styles', () ->
			expect(ansiparse 'default, \x1b[31;1mbright red, \x1b[34;46mbright blue on cyan, \x1b[22mblue on cyan')
				.toBe '<span class="foregroundDefault backgroundDefault">default,&nbsp</span>' +
					'<span class="foregroundRed backgroundDefault bright">bright&nbspred,&nbsp</span>' +
					'<span class="foregroundBlue backgroundCyan bright">bright&nbspblue&nbspon&nbspcyan,&nbsp</span>' +
					'<span class="foregroundBlue backgroundCyan">blue&nbspon&nbspcyan</span>'

		it 'should overwrite old characters with new styles', () ->
			expect(ansiparse 'plain\x1b[0G\x1b[32mgreen').toBe '<span class="foregroundGreen backgroundDefault">green</span>'
