'use strict'

window.Welcome = ['$scope', 'rpc', ($scope, rpc) ->
	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () -> 
				$scope.repositories = [allRepositories].concat repositories

	allRepositories = {id: -1, name: 'All'}
	$scope.repositories = [allRepositories]
	$scope.currentRepositoryOption = $scope.repositories[0].id

	$scope.filterOptions = [
		{id: 'pastSeven', name: 'Past 7 days'},
		{id: 'pastFourteen', name: 'Past 14 days'},
		{id: 'pastMonth', name: 'Past month'},
		{id: 'pastThreeMonths', name: 'Past 3 months'},
		{id: 'pastSixMonths', name: 'Past 6 months'},
		{id: 'pastYear', name: 'Past year'}
	]

	$scope.currentFilterOption = $scope.filterOptions[0].id


	$scope.timeInterval =
		start: 0
		end: (new Date()).getTime()
	$scope.numChanges =
		passed: 500
		failed: 300


	$scope.filterSelected = (filterOption) ->
		timeInDay = 24 * 60 * 60 * 1000
		startTime = null
		currentTime = (new Date()).getTime()

		switch filterOption
			when 'pastSeven' then startTime = currentTime - 7 * timeInDay
			when 'pastFourteen' then startTime = currentTime - 14 * timeInDay
			when 'pastMonth' then startTime = currentTime - 30 * timeInDay
			when 'pastThreeMonths' then startTime = currentTime - 90 * timeInDay
			when 'pastSixMonths' then startTime = currentTime - 180 * timeInDay
			when 'pastYear' then startTime = currentTime - 365 * timeInDay
			else throw new Error 'Unexpected filter option: ' + filterOption

		console.log new Date startTime
		# requestParams =
		# 	repositories: [0, 1]
		# 	startTime: startTime
		# rpc.makeRequest 'changes', 'read', 'getChangesFromTime', requestParams, (error, changes) ->
		# 	$scope.changes = changes

	$scope.changes = [
		{timestamp: 1358040566846, status: 'passed'}, 
		{timestamp: 1358040566886, status: 'passed'}, 
		{timestamp: 1358040566946, status: 'failed'}, 

		{timestamp: 1360718966846, status: 'passed'},
		{timestamp: 1360718966856, status: 'failed'},

		{timestamp: 1363134566846, status: 'passed'},
		{timestamp: 1363134566856, status: 'passed'},
		{timestamp: 1363134566876, status: 'passed'},

		{timestamp: 1365812966846, status: 'failed'},
		{timestamp: 1365812966856, status: 'failed'},
		{timestamp: 1365812966866, status: 'passed'},

		{timestamp: 1368404966846, status: 'passed'},
		{timestamp: 1368404966856, status: 'passed'},
		{timestamp: 1368404966866, status: 'failed'},
		{timestamp: 1368404966876, status: 'passed'},

		{timestamp: 1371083366846, status: 'passed'},
		{timestamp: 1371083366856, status: 'passed'}
	]

	setTimeout (() -> $scope.$apply () ->
		$scope.changes.push
			timestamp: 1371083366876
			status: 'failed'
		), 1000

	setTimeout (() -> $scope.$apply () ->
		$scope.changes.push
			timestamp: 1371083366886
			status: 'failed'
		), 2000

	setTimeout (() -> $scope.$apply () ->
		$scope.changes.push
			timestamp: 1371083366896
			status: 'passed'
		), 3000

	setTimeout (() -> $scope.$apply () ->
		$scope.changes.push
			timestamp: 1371083366996
			status: 'passed'
		), 4000





	getRepositories()
]