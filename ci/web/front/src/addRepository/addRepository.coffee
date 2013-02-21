'use strict'

window.AddRepository = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.stage = 'first'
	$scope.stageOneErrorModalVisible = false
	$scope.createRepositoryErrorModalVisible = false

	$scope.repository = {}

	$scope.moveToStageTwo = () ->
		rpc.makeRequest 'repositories', 'create', 'getSshPublicKey', $scope.repository, (error, publicKey) ->
			$scope.$apply () ->
				if error?
					console.error error
					$scope.stageOneErrorModalVisible = true
				else 
					$scope.repository.sshKey = publicKey
					$scope.stage = 'second'

	$scope.createRepository = () ->
		rpc.makeRequest 'repositories', 'create', 'createRepository', $scope.repository, (error) ->
			if error?
				console.error error
				$scope.createRepositoryErrorModalVisible = true
			else
				$scope.stage = 'third'
]