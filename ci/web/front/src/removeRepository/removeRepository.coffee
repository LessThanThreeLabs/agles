'use strict'

window.RemoveRepository = ['$scope', '$routeParams', 'rpc', ($scope, $routeParams, rpc) ->
	$scope.stage = 'first'

	$scope.repository = {}
	$scope.repository.id = $routeParams.id
	$scope.repository.name = $routeParams.name 

	$scope.removeRepository = () ->
		$scope.stage = 'second'
]