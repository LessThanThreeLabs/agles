'use strict'

window.Welcome = ['$scope', 'rpc', ($scope, rpc) ->
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
]