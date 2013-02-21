'use strict'

window.AddRepository = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.stage = 'first'
	$scope.verifyConnectionErrorModalVisible = false

	$scope.repository = {}

	$scope.moveToStageTwo = () ->
		rpc.makeRequest 'repositories', 'create', 'getSshPublicKey', $scope.repository, (error, publicKey) ->
			$scope.$apply () ->
				if error? then console.error error
				else 
					$scope.repository.sshKey = publicKey
					$scope.stage = 'second'

	$scope.verifyConnection = () ->
		rpc.makeRequest 'repositories', 'create', 'createRepository', $scope.repository, (error) ->
			if error?
				console.error error
				$scope.verifyConnectionErrorModalVisible = true
			else
				$scope.stage = 'third'
]