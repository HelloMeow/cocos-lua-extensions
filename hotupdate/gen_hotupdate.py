#!/usr/bin/python
# encoding: utf-8
from git import Repo
import os
import hashlib
import re
import datetime
import json
import shutil

# Config
CONF = json.loads(open('cfg_hotupdate.txt', 'r').read())

def genVersion(version_path):
	major_version = CONF['c_major_version']
	# -- compare old version.manifest, get version info.
	old_version = None
	if os.path.exists(version_path):
		with open(version_path, 'r') as fp:
			old = json.loads(fp.read())
			old_version = old['version']
	
	# -- generate new version
	today = datetime.datetime.now().strftime('%Y%m%d')
	minor = 0
	
	if old_version:
		match = re.match(r'(\d+)\.(\d+)\.(\d+)', old_version)
		if not match:
			print "Error:Version format illegal: " + old_version + ', should be major.date.minor'
			return
		major = match.group(1)
		date  = match.group(2)
		if major == major_version and date == today:
			minor = int(match.group(3))
		
	return major_version + '.' + today + '.' + str(minor+1)

# split given path to array of components
def paths(p) :
	head,tail = os.path.split(p)
	components = []
	while len(tail)>0:
		components.insert(0,tail)
		head,tail = os.path.split(head)
	return components
	
def clearDir(root):
	print 'Clearing dir', root
	for f in os.listdir(root):
		path = os.path.join(root, f)
		if os.path.isfile(path):
			os.remove(path)
		elif os.path.isdir(path):
			shutil.rmtree(path)

# copy files
def copyFiles(assets_json):
	for k in assets_json:
		# generate intermediate dirs if not exists
		destpath = os.path.join(CONF['c_project_dir'], os.path.dirname(k))
		if not os.path.exists(destpath):
			os.makedirs(destpath)
		# copy files
		shutil.copyfile(os.path.join(CONF['c_repo_dir'], k), 
			os.path.join(CONF['c_project_dir'], k))
# generate manifests
def genManifests(assets_json, new_version):
	project_manifest_path = os.path.join(CONF['c_project_dir'], CONF['c_project_manifest_name'])
	version_manifest_path = os.path.join(CONF['c_version_dir'], CONF['c_version_manifest_name'])
	o = {}
	# package url
	o['packageUrl'] = CONF['c_package_url']
	# manifest url
	o['remoteManifestUrl'] = CONF['c_manifest_url']
	# version url
	o['remoteVersionUrl'] = CONF['c_version_url']
	# version
	o['version'] = new_version
	# engine version
	o['engineVersion'] = "Quick 3.5"
	
	# -- save to version.manifest
	with open(version_manifest_path, 'w') as fp:
		fp.write(json.dumps(o, indent=4))
	
	# search path
	o['searchPaths'] = []
	
	# assets
	o['assets'] = assets_json
		
	# -- save to project.manifest
	with open(project_manifest_path, 'w') as fp:
		fp.write(json.dumps(o, indent=4))
		
	return 'Done!'

# generate md5 for given file
def genMd5(f):
	return hashlib.md5(open(f, 'rb').read()).hexdigest()

def genMd5JsonForFiles(filelist):
	o = {}
	for f in filelist:
		o[f] = {"md5":genMd5(os.path.join(CONF['c_repo_dir'], f))}
	return o

# filter wanted files
def getWantedFiles(filelist):
	l = []
	for f in filelist:
		basedir = paths(f)[0]
		if basedir in CONF['c_dir_0']:
			l.append(f)
	return l

# get file change history from c_base_commit to HEAD
def getChangedList():
	repo = Repo(CONF['c_repo_dir'])
	assert(repo)
        repo.git.pull()
	l = []
	hcommit = repo.commit(CONF['c_base_commit'])
	# 'A' - added
	for d in hcommit.diff(CONF['c_head_commit']).iter_change_type('A'):
		l.append(d.a_path)
	# 'M' - modified
	for d in hcommit.diff(CONF['c_head_commit']).iter_change_type('M'):
		l.append(d.a_path)
	# 'R' - renamed
	for d in hcommit.diff(CONF['c_head_commit']).iter_change_type('R'):
		l.append(d.b_path)
	return l

# ------------------------------------
def gen_hotupdate():
	# get changed file list from base to HEAD commit
	l = getChangedList()
	if len(l) <= 0:
		print 'Nothing updated, ignore'
		return
	j = genMd5JsonForFiles(getWantedFiles(l))
	version_manifest_path = os.path.join(CONF['c_version_dir'], 
		CONF['c_version_manifest_name'])
	new_version = genVersion(version_manifest_path)
	print 'New version:', new_version
	clearDir(CONF['c_project_dir'])
	clearDir(CONF['c_version_dir'])
	genManifests(j, new_version)
	copyFiles(j)
	
if __name__ == '__main__':
	gen_hotupdate()
	
