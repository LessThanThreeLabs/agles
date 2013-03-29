'use strict'

angular.module('koality.d3.directive', []).
	directive('changeStatus', ['$window', ($window) ->
		restrict: 'E'
		replace: true
		scope: 
			changes: '=changes'
			timeInterval: '=timeInterval'
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
					.x((d, index) -> return x allIntervals[index])
					.y((d) -> return y d)

			createHistogramForStatus = (binner, interval, allIntervals, status='all') ->
				histogram = (0 for index in [0...allIntervals.length])

				for change in scope.changes
					continue if status isnt 'all' and change.status isnt status
					index = binner interval.floor new Date(change.endTime)
					histogram[index]++

				return histogram

			getGreatestNumberOfChanges = (allHistogram, passedHistogram, failedHistogram) ->
				return d3.max [d3.max(allHistogram), d3.max(passedHistogram), d3.max(failedHistogram)]

			drawGraph = () ->
				startTime = new Date(scope.timeInterval.start)
				endTime = d3.max [new Date(scope.timeInterval.end),
					d3.max(scope.changes, (change) -> return new Date(change.endTime))]

				interval = d3.time.day
				allIntervals = interval.range interval.floor(startTime), interval.ceil(endTime)

				binner = d3.time.scale()
					.domain([allIntervals[0], allIntervals[allIntervals.length - 1]])
					.range([0, allIntervals.length - 1])
					.interpolate(d3.interpolateRound)

				allHistogram = createHistogramForStatus binner, interval, allIntervals
				passedHistogram = createHistogramForStatus binner, interval, allIntervals, 'passed'
				failedHistogram = createHistogramForStatus binner, interval, allIntervals, 'failed'

				x = d3.time.scale()
					.domain([allIntervals[0], allIntervals[allIntervals.length-1]])
					.range([padding.left+axisBuffer, width-padding.right])
				y = d3.scale.linear()
					.domain([0, getGreatestNumberOfChanges(allHistogram, passedHistogram, failedHistogram)])
					.range([height-padding.bottom-axisBuffer, padding.top])
				yStart = (value) -> return y 0

				xAxis = d3.svg.axis().scale(x).ticks(5).tickFormat(d3.time.format '%m/%d').orient 'bottom'
				yAxis = d3.svg.axis().scale(y).ticks(5).orient 'left'

				allPath.datum(allHistogram)
					.attr('d', computeChangeLine x, yStart, allIntervals)
					.transition().duration(500)
					.attr('d', computeChangeLine x, y, allIntervals)
				passedPath.datum(passedHistogram)
					.attr('d', computeChangeLine x, yStart, allIntervals)
					.transition().duration(750)
					.attr('d', computeChangeLine x, y, allIntervals)
				failedPath.datum(failedHistogram)
					.attr('d', computeChangeLine x, yStart, allIntervals)
					.transition().duration(1000)
					.attr('d', computeChangeLine x, y, allIntervals)

				xAxisLabel.call xAxis
				yAxisLabel.call yAxis

			clearGraph = () ->
				allPath.datum []
				passedPath.datum []
				failedPath.datum []

			handleUpdate = (newValue, oldValue) ->
				if not scope.changes? or scope.changes.length is 0 or not scope.timeInterval?
					clearGraph()
				else 
					drawGraph()

			scope.$watch 'changes', handleUpdate, true
			scope.$watch 'timeInterval', handleUpdate, true
	])
