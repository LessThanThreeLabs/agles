'use strict'

window.AddRepository = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.stage = 'first'
	$scope.verifyConnectionErrorModalVisible = false

	$scope.repository = {}
	$scope.repository.sshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxvvK4FBlsGzexbr5IMEfvp0LfaPg2LHJlrHPqawe66136PrXPQHDJUN5rUb8LEulVVMsW6fRjG5oAytmOZ/DCGlxLN7vN65c8adw67lLjHVpQ8uHJteRkq0EuL/rZSPBLm2fP/yAeJYRiJP6fob24PpklwIz5cr9tGHH7DJmzk69PzU3AdL7DbUZ/vIay9cPFV5sQ3BGTpHSQlKunWWtN+m6Lp5ZAwY6+bvdw9E/8PYp7+aBRpbPDJ4f3uiMzcmzSxPqcoz+PuCzljHeYmm/vYF2XmeB66cAzPSig3xAz5YVgTFBW9FWvg6W5DcdPsUQGqeyJta7ppIQW88HOpNk5 jordannpotter@gmail.com'

	rpc.makeRequest 'repositories', 'create', 'getSshPublicKey', name: 'hello', (error, publicKey) ->
		if error? then console.error error
		else console.log publicKey

	$scope.addRepository = () ->
		$scope.stage = 'second'

	$scope.verifyConnection = () ->
		$scope.verifyConnectionErrorModalVisible = true
		# $scope.stage = 'third'
]