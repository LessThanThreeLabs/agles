'use strict'

angular.module('koality.d3.directive', []).
	directive('changeStatusTwo', ['$window', ($window) ->
		restrict: 'E'
		replace: true
		scope: changes: '=changes'
		template: '<svg class="changeStatuses" xmlns="http://www.w3.org/2000/svg" version="1.1"></svg>'
		link: (scope, element, attributes) ->
			width = element.width()
			height = element.height()

			x = d3.time.scale().range([0, width])
			y = d3.scale.linear().range([height, 0])
			xAxis = d3.svg.axis().scale(x).orient 'bottom'
			yAxis = d3.svg.axis().scale(y).orient 'left'

			line = d3.svg.line()
				.x((d) -> return x(d.date))
				.y((d) -> return y(d.value))

			svg = d3.select(element[0]).append('g')
			svg.append('g')
				.attr('class', 'xAxis')
				.attr('transform', 'translate(0, 450)')
				.call(xAxis)
			svg.append('g')
				.attr('class', 'yAxis')
				.attr('transform', 'translate(50, 0)')
				.call(yAxis)

			path = svg.append('path')

			handleChangesUpdate = (newValue, oldValue) ->
				console.log newValue

				x.domain(d3.extent(newValue, (d) -> return d.date))
				y.domain(d3.extent(newValue, (d) -> return d.value))

				path.datum(newValue)
					.attr('class', 'line')
					.attr('d', line)

			scope.$watch 'changes', handleChangesUpdate, true
	]).
	directive('changeStatus', ['$window', ($window) ->
		restrict: 'E'
		replace: true
		scope: changes: '=changes'
		template: '<svg class="changeStatuses" xmlns="http://www.w3.org/2000/svg" version="1.1"></svg>'
		link: (scope, element, attributes) ->
			width = element.width()
			height = element.height()

			# x = d3.time.scale().range([0, width])
			x = d3.scale.linear().range([0, width])
			y = d3.scale.linear().range([height, 0])

			line = d3.svg.line()
				.x((d, i) -> return x i)
				.y((d) -> return y d)

			svg = d3.select(element[0]).append('g')
			path = svg.append('path')

			handleChangesUpdate = (newChanges, oldChanges) ->
				binner = d3.time.scale()
				interval = d3.time.month

				dateRange = d3.extent newChanges, (change) -> return new Date change.timestamp
				console.log dateRange

				allIntervals = interval.range interval.floor(dateRange[0]), interval.ceil(dateRange[1])
				console.log allIntervals

				binner.domain [allIntervals[0], allIntervals[allIntervals.length - 1]]
				binner.range [0, allIntervals.length - 1]
				binner.interpolate d3.interpolateRound

				histogram = (0 for index in [0...allIntervals.length])
				for change in newChanges
					index = binner interval.floor new Date change.timestamp
					histogram[index]++

				console.log histogram

				x.domain [0, allIntervals.length-1]
				y.domain [0, d3.max histogram]

				path.datum(histogram)
					.attr('class', 'line')
					.attr('d', line)

			scope.$watch 'changes', handleChangesUpdate, true
	])

