assert = require 'assert'


exports.create = () ->
	return new SystemSettingsInformationValidator()


class SystemSettingsInformationValidator
	
	domainNameRegex: new RegExp "^[\w]+$"
	awsIdRegex: new RegExp "^[\w]+$"
	awsSecretRegex: new RegExp "^[\w]+$"


	getInvalidDomainNameString: () =>
		return 'Invalid domain name'


	isValidDomainName: (domainName) =>
		return domainName? and domainName.match @domainNameRegex


	getInvalidAwsIdString: () =>
		return 'Invaild aws id'


	isValidAwsId: (awsId) =>
		return awsId? and awsId.length >= 16 and awsId.length <= 32 and awsId.match @awsIdRegex


	getInvalidAwsSecretString: () =>
		return 'Invaild aws secret'


	isValidAwsSecret: (awsSecret) =>
		return awsSecret? and awsSecret.match @awsIdRegex


	getInvalidNumWaitingInstancesString: () =>
		return 'Invalid number of waiting instances'


	isValidNumWaitingInstances: (numWaiting) =>
		return numWaiting >= 0 and numWaiting <= 1000


	getInvalidMaxRunningInstancesString: () =>
		return 'Invalid number of max running instances'


	isValidMaxRunningInstances: (maxRunning) =>
		return maxRunning >= 1 and maxRunning <= 10000
