#!/usr/local/bin/python

import os
import subprocess

sites_to_check=[]

for site in sites_to_check:
	command="curl -s --head  --request GET %s | grep '200 OK'" % (site)
	
	p = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
	(output, err) = p.communicate()

	if not output:
		print "Site down:%s" % (site)
		subprocess.Popen('play alarm.mp3', stdout=subprocess.PIPE, shell=True)
	else:
		print "site up"
