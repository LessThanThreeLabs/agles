'use strict'

window.Header = ['$scope', '$location', ($scope, $location) ->
	# $scope.loggedIn = initialState.loggedIn
	# $scope.isAdmin = initialState.user.isAdmin

	# $scope.feedback = {}
	# $scope.feedback.modalVisible = false
	# $scope.feedback.showSuccess = false

	# $scope.visitHome = () -> $location.path('/').search({})

	# $scope.submitFeedback = () ->
	# 	requestParams =
	# 		feedback: $scope.feedback.text
	# 		userAgent: navigator.userAgent
	# 		screen: window.screen
	# 	rpc.makeRequest 'users', 'update', 'submitFeedback', requestParams

	# 	$scope.feedback.showSuccess = true

	# $scope.$watch 'feedback.modalVisible', (newValue, oldValue) ->
	# 	if not newValue
	# 		$scope.feedback.text = ''
	# 		$scope.feedback.showSuccess = false
]

