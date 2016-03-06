#!/usr/bin/env python2.7
#
# Shamelessly lifted from sickrage/lib/helpers.py

import time
import random
import datetime

def generateApiKey():
	""" Return a new randomized API_KEY"""

	try:
		from hashlib import md5
	except ImportError:
		from md5 import md5

	# Create some values to seed md5
	t = str(time.time())
	r = str(random.random())

	# Create the md5 instance and give it the current time
	m = md5(t)

	# Update the md5 instance with the random variable
	m.update(r)

	# Return a hex digest of the md5, eg 49f68a5c8493ec2c0bf489821c21fc3b
	return m.hexdigest()

print "New API Key: %s" % generateApiKey()
