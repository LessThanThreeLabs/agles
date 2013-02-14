'use strict'

window.AddRepository = ['$scope', '$location', 'socket', ($scope, $location, socket) ->
	$scope.stage = 'first'

	$scope.repository = {}
	$scope.repository.sshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxvvK4FBlsGzexbr5IMEfvp0LfaPg2LHJlrHPqawe66136PrXPQHDJUN5rUb8LEulVVMsW6fRjG5oAytmOZ/DCGlxLN7vN65c8adw67lLjHVpQ8uHJteRkq0EuL/rZSPBLm2fP/yAeJYRiJP6fob24PpklwIz5cr9tGHH7DJmzk69PzU3AdL7DbUZ/vIay9cPFV5sQ3BGTpHSQlKunWWtN+m6Lp5ZAwY6+bvdw9E/8PYp7+aBRpbPDJ4f3uiMzcmzSxPqcoz+PuCzljHeYmm/vYF2XmeB66cAzPSig3xAz5YVgTFBW9FWvg6W5DcdPsUQGqeyJta7ppIQW88HOpNk5 jordannpotter@gmail.com'

	$scope.addRepository = () ->
		# socket.makeRequest 'repositories', 'create', 'createRepository', $scope.repository, (result) ->
		# 	console.log 'result: ' + result
		$scope.stage = 'second'

	$scope.verifyConnection = () ->
		$scope.stage = 'third'
]