'use strict'

window.AddRepository = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.stage = 'first'
	$scope.stageOneErrorModalVisible = false
	$scope.createRepositoryErrorModalVisible = false

	$scope.repository = {}

	$scope.moveToStageTwo = () ->
		rpc.makeRequest 'repositories', 'create', 'getSshPublicKey', $scope.repository, (error, publicKey) ->
			$scope.$apply () ->
				$scope.repository.sshKey = publicKey
				$scope.stage = 'second'

	$scope.createRepository = () ->
		rpc.makeRequest 'repositories', 'create', 'createRepository', $scope.repository, (error) ->
			$scope.$apply () -> $scope.stage = 'third'
]