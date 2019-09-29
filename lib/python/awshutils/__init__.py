# Header will go here when ready to publish
import os
import sys
import collections
import copy
import time
import logging
from awshutils.logger import LOG_CONTEXT

_log = logging.getLogger(LOG_CONTEXT)

__version__ = '0.1'

CONST_MIN_BOTO_VERSION = '2.31.0'
CONST_DIR_TMP = "/tmp"
CONST_AWSH_ROOT = os.getenv('AWSH_ROOT', '')

###############################################################################
# Classes
###############################################################################


###############################################################################
# Functions
###############################################################################


def check_imports():
    # Check for Boto installation and correct version
    try:
        import boto
    except ImportError:
        print("The 'boto' module does not seem to be available, exiting.")
        sys.exit(1)

    try:
        import colorama
    except ImportError:
        print("The 'colorama' module does not seem to be available, exiting.")
        sys.exit(1)

    from distutils.version import StrictVersion
    if StrictVersion(boto.__version__) < StrictVersion(CONST_MIN_BOTO_VERSION):
        print('Error: the boto package version should be at least: {0}; installed: {1}'.format(CONST_MIN_BOTO_VERSION, boto.__version__))
        sys.exit(1)


def clean_up(returnValue=0):
    sys.exit(returnValue)


def str2bool(v):
    _log.debug('Attempting to convert [{}] to Boolean value'.format(v))
    return str(v).lower() in ("yes", "true", "t", "1")


def wait_while(instance, status):
    # Sleep initially in the event that we've just created the instance
    time.sleep(5)
    instance.update()
    while instance.state == status:
        time.sleep(5)
        instance.update()


def flatten_mixed_list(l):
    for el in l:
        if isinstance(el, collections.Iterable) and not isinstance(el, basestring):
            for sub in flatten_mixed_list(el):
                yield sub
        else:
            yield el


def add_tag_pair(tags, key_name, value):
    """Updates the provided list of tags with a new k:v pair added with the
    content {'Key': 'key_name', 'Value': 'value'} and returns a new tags
    object"""

    _log.debug('Tag - Adding tag[{0}] with value [{1}] to tags'.format(key_name, value))
    c = copy.deepcopy(tags)
    new_pair = {'Key': key_name, 'Value': value}
    c.append(new_pair)
    return(c)
