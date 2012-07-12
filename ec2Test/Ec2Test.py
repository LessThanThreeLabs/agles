import boto
import time

def runTest():
	ec2Connection = boto.connect_ec2('ACCESS_KEY', 'SECRET_ACCESS_KEY')

	instance = reserveInstance(ec2Connection, 'ami-bb709dd2')
	volume = createAndAttachVolume(ec2Connection, instance, 8)
	snapshot = createSnapshot(ec2Connection, volume)

	time.sleep(60)

	terminateSnapshot(ec2Connection, snapshot)
	terminateVolume(ec2Connection, instance, volume)
	terminateInstance(ec2Connection, instance)	


def reserveInstance(ec2Connection, imageId):
	keyName = 'sampleKey'
	createKeyPair(ec2Connection, keyName);
	reservation = ec2Connection.run_instances(image_id = imageId, key_name = keyName)
	instance = reservation.instances[0]
	waitForEc2InstanceToStart(ec2Connection, instance)
	return instance;


def createKeyPair(ec2Connection, keyPairName):
	if ec2Connection.get_key_pair(keyPairName) != None:
		return

	key_pair = ec2Connection.create_key_pair(keyPairName)
	key_pair.save('/Volumes/Slave/Lo7us/.ssh')
	

def waitForEc2InstanceToStart(ec2Connection, instance):
	print 'waiting for instance to start...'
	while not instance.update() == 'running':
		time.sleep(5)
	print 'done!'


def terminateInstance(ec2Connection, instance):
	print 'terminating instance ' + str(instance)
	ec2Connection.terminate_instances([instance.id])


def createAndAttachVolume(ec2Connection, instance, size):
	volume = ec2Connection.create_volume(8, instance.placement)
	waitForVolumeToStart(volume)
	ec2Connection.attach_volume(volume.id, instance.id, '/dev/sdh')
	return volume;


def waitForVolumeToStart(volume):
	print 'waiting for volume...'
	while not volume.status == 'available':
		time.sleep(10)
		volume.update()
	print 'done!'


def terminateVolume(ec2Connection, instance, volume):
	print 'terminating volume ' + str(volume)
	ec2Connection.detach_volume(volume.id, instance.id, '/dev/sdh')
	time.sleep(30)  # wait for the volume to detach... I didn't care to write a smart function to do this... it doesn't actually take this long...
	ec2Connection.delete_volume(volume.id)


def createSnapshot(ec2Connection, volume):
	snapshot = ec2Connection.create_snapshot(volume.id)
	return snapshot


def terminateSnapshot(ec2Connection, snapshot):
	print 'terminating snapshot ' + str(snapshot)
	ec2Connection.delete_snapshot(snapshot.id)


runTest()