# sitecustomize.py
# application = global
# ver = 76e9f69f9b04199f0d4cb0395e234b06

import site
import platform
import os
import sys

site_version = sys.version[:3]

path = os.path.join(os.path.sep, 'usr', 'local', 'lib', 'python'+site_version)
if os.path.exists(path):
    site.addsitedir(path)

path = os.path.join(os.path.sep, 'usr', 'local', 'lib', 'python'+site_version, 'site-packages')
if os.path.exists(path):
    site.addsitedir(path)

path = os.path.join(os.path.sep, 'opt', 'lib', 'python'+site_version)
if os.path.exists(path):
    site.addsitedir(path)

path = os.path.join(os.path.sep, 'opt', 'lib', 'python'+site_version, 'site-packages')
if os.path.exists(path):
    site.addsitedir(path)

path = os.path.join(os.path.sep, 'opt', 'media', 'python'+site_version)
if os.path.exists(path):
    site.addsitedir(path)

path = os.path.join(os.path.sep, 'opt', 'media', 'python'+site_version, 'site-packages')
if os.path.exists(path):
    site.addsitedir(path)

