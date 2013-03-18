'use strict'

window.Welcome = ['$scope', 'rpc', ($scope, rpc) ->
	setupFilterOptions = () ->
		$scope.filterOptions = [
			{id: 'pastSeven', name: 'Past 7 days'},
			{id: 'pastFourteen', name: 'Past 14 days'},
			{id: 'pastMonth', name: 'Past month'},
			{id: 'pastThreeMonths', name: 'Past 3 months'},
			{id: 'pastSixMonths', name: 'Past 6 months'},
			{id: 'pastYear', name: 'Past year'}
		]
		$scope.currentFilterOptionId = $scope.filterOptions[0].id

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () -> 
				allRepositories = {id: -1, name: 'All'}
				$scope.repositories = [allRepositories].concat repositories
				$scope.currentRepositoryOptionId = $scope.repositories[0].id

				setupFilterOptions()
				retrieveChanges()

	getStartTimeFromFilterOption = () ->
		timeInDay = 24 * 60 * 60 * 1000
		currentTime = (new Date()).getTime()

		switch $scope.currentFilterOptionId
			when 'pastSeven' then return currentTime - 7 * timeInDay
			when 'pastFourteen' then return currentTime - 14 * timeInDay
			when 'pastMonth' then return currentTime - 30 * timeInDay
			when 'pastThreeMonths' then return currentTime - 90 * timeInDay
			when 'pastSixMonths' then return currentTime - 180 * timeInDay
			when 'pastYear' then return currentTime - 365 * timeInDay
			else throw new Error 'Unexpected filter option: ' + $scope.currentFilterOptionId

	updateChangesSummary = () ->
		$scope.timeInterval =
			start: getStartTimeFromFilterOption()
			end: (new Date()).getTime()

		$scope.numChanges = 
			passed: 0
			failed: 0

		for change in $scope.changes
			if change.status is 'passed' then $scope.numChanges.passed++
			if change.status is 'failed' then $scope.numChanges.failed++

	retrieveChanges = () ->
		return if not $scope.repositories? or $scope.repositories.length is 0

		repositories = null
		if $scope.currentRepositoryOptionId is -1
			repositories = $scope.repositories
				.map((repository) -> return repository.id)
				.filter((repositoryId) -> repositoryId >= 0)
		else
			repositories = [$scope.currentRepositoryOptionId]

		requestParams =
			repositories: repositories
			timestamp: getStartTimeFromFilterOption() / 1000  # backend is in unix time
		rpc.makeRequest 'changes', 'read', 'getChangesFromTimestamp', requestParams, (error, changes) ->
			$scope.$apply () ->
				$scope.changes = changes.filter (change) -> return change.endTime?
				updateChangesSummary()

	$scope.filterSelected = (filterOptionId) ->
		$scope.currentFilterOptionId = filterOptionId
		retrieveChanges()

	$scope.repositorySelected = (repositoryId) ->
		$scope.currentRepositoryOptionId = repositoryId
		retrieveChanges()

	getRepositories()
]