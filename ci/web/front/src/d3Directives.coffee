'use strict'

angular.module('koality.d3.directive', []).
	directive('changeStatus', ['$window', ($window) ->
		restrict: 'E'
		replace: true
		scope: changes: '=changes'
		template: '<svg class="changeStatuses" xmlns="http://www.w3.org/2000/svg" version="1.1"></svg>'
		link: (scope, element, attributes) ->
			padding = {top: 10, left: 50, right: 20, bottom: 50}
			width = element.width()
			height = element.height()
			axisBuffer = 10
			lineTransitionTime = 1500

			svg = d3.select(element[0]).append 'g'

			allPath = svg.append('path').attr 'class', 'allLine'
			passedPath = svg.append('path').attr 'class', 'passedLine'
			failedPath = svg.append('path').attr 'class', 'failedLine'

			xAxisLabel = svg.append('g').attr('class', 'xAxis').attr 'transform', "translate(0, #{height-padding.bottom})"
			yAxisLabel = svg.append('g').attr('class', 'yAxis').attr 'transform', "translate(#{padding.left}, 0)"

			computeChangeLine = (x, y, allIntervals) ->
				return d3.svg.line()
					.interpolate('cardinal')
					.x((d, index) -> return x allIntervals[index])
					.y((d) -> return y d)

			createHistogramForStatus = (changes, binner, interval, allIntervals, status='all') ->
				histogram = (0 for index in [0...allIntervals.length])
				for change in changes
					continue if status isnt 'all' and change.status isnt status
					index = binner interval.floor new Date change.timestamp
					histogram[index]++
				return histogram

			handleChangesUpdate = (newChanges, oldChanges) ->
				dateRange = d3.extent newChanges, (change) -> return new Date change.timestamp

				interval = d3.time.day
				allIntervals = interval.range interval.floor(dateRange[0]), interval.ceil(dateRange[1])

				binner = d3.time.scale()
					.domain([allIntervals[0], allIntervals[allIntervals.length - 1]])
					.range([0, allIntervals.length - 1])
					.interpolate(d3.interpolateRound)

				allHistogram = createHistogramForStatus newChanges, binner, interval, allIntervals
				passedHistogram = createHistogramForStatus newChanges, binner, interval, allIntervals, 'passed'
				failedHistogram = createHistogramForStatus newChanges, binner, interval, allIntervals, 'failed'

				x = d3.time.scale()
					.domain([allIntervals[0], allIntervals[allIntervals.length-1]])
					.range([padding.left+axisBuffer, width-padding.right])
				y = d3.scale.linear()
					.domain([0, d3.max [d3.max(allHistogram), d3.max(passedHistogram), d3.max(failedHistogram)]])
					.range([height-padding.bottom-axisBuffer, padding.top])

				xAxis = d3.svg.axis().scale(x).orient 'bottom'
				yAxis = d3.svg.axis().scale(y).orient 'left'

				allPath.datum(allHistogram).transition().duration(lineTransitionTime).attr('d', computeChangeLine x, y, allIntervals)
				passedPath.datum(passedHistogram).transition().duration(lineTransitionTime).attr('d', computeChangeLine x, y, allIntervals)
				failedPath.datum(failedHistogram).transition().duration(lineTransitionTime).attr('d', computeChangeLine x, y, allIntervals)

				xAxisLabel.call xAxis
				yAxisLabel.call yAxis

			scope.$watch 'changes', handleChangesUpdate, true
	])

