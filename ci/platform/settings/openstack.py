version = "2"
username = "lessthanthree"
api_key = "8eb41c1eaab4e10b3e7603d7630b26c3"
auth_url = "https://identity.api.rackspacecloud.com/v2.0/"
auth_system = "rackspace"
region_name = "DFW"

credentials = ([version, username, api_key, username],
	dict(auth_url=auth_url, auth_system=auth_system,
	region_name=region_name))

VM_IMAGE_NEWEST_PREFIX = "precise64_box_"


def image_filter(image):
	'''Determine which images to allow.
	May be overridden for staging or special user boxes.'''
	return image.name.startswith(VM_IMAGE_NEWEST_PREFIX)
