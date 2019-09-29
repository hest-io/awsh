import os
import sys
import time
import shlex
import logging
import yaml
import optparse
import subprocess
import collections
import ConfigParser
from boto.ec2 import elb
from boto import ec2, vpc
from rainbow_logging_handler import RainbowLoggingHandler
from colorama import Fore as FG, Style as STYLE

###############################################################################
# CONFIG - Begin
###############################################################################

CONST_MIN_BOTO_VER = '2.29.1'
CONST_DIR_TMP = "/tmp"
CONST_LOG_FORMAT_FILE = '%(asctime)s %(levelname)-5.5s %(module)s:%(lineno)04.4d %(funcName)-25.25s %(message)s'
CONST_LOG_FORMAT_CONSOLE = '%(asctime)s %(levelname)-5.5s %(message)s'
CONST_AWSH_ROOT = os.getenv('AWSH_ROOT', '')

###############################################################################
# CONFIG - End (Do Not Edit Below)
###############################################################################

log = logging.getLogger(__name__)

###############################################################################
# Classes
###############################################################################

class IterRegistry(type):
    """Helper class for iteration through objects's properties"""

    def __iter__(self, cls):
        return iter(cls._registry)

class MyOptionParser(optparse.OptionParser):
    """Command Line options parser"""

    def print_help(self):
        """Standard usage() handler"""
        optparse.OptionParser.print_help(self)
        # print __doc__

class AWS_VPC:
    pass

class AWS_DX_CONNECTION:
    pass

class AWS_DX_INTERFACE:
    pass

class ConfigObject:

    __metaclass__ = IterRegistry
    _registry = []
    obj_type = None

    def __init__(self, name):
        self.name = name

    def __str__(self):
        return ('{0}: type={1}'.format(self.name, self.obj_type))

    def add_property(self, name, value):
        # create local fget and fset functions
        fget = lambda self: self._get_property(name)
        fset = lambda self, value: self._set_property(name, value)
        # add property to self
        setattr(self.__class__, name, property(fget, fset))
        # add corresponding local variable
        setattr(self, '_' + name, value)

    def _set_property(self, name, value):
        setattr(self, '_' + name, value)

    def _get_property(self, name):
        return getattr(self, '_' + name)


###############################################################################
# Functions
###############################################################################

def load_params_file(filename):
    """Load params from the specificed filename and return the params as a
    dictionary"""

    log.debug('Loading parms from {0}'.format(filename))

    config = ConfigParser.ConfigParser()
    config.optionxform = str
    config.read(filename)

    object_list = config.sections()

    params = {}

    for config_object in object_list:

        o = ConfigObject(name=config_object)
        all_attributes = config.options(config_object)

        for attribute in all_attributes:

            value = config.get(config_object, attribute)
            # Replace the AWSH_ROOT variable with the current value if present
            value = value.replace('$AWSH_ROOT', CONST_AWSH_ROOT)

            log.debug('ConfigObject[{0}] {1}: {2}'.format(config_object, attribute, value))
            o.add_property(attribute, value)

        params[o.name] = o

    return params


def get_config_from_yaml_file(f):
    """Load params from the specified filename and return the params as a
    dictionary"""

    from os.path import expanduser
    filename = expanduser(f)

    log.debug('Loading parms from {0}'.format(filename))

    with open(filename, 'r') as ymlfile:
        config = yaml.load(ymlfile)

    return config



def validate_subnets(v, vpc_connection, subnet_names=[]):
    # Subnets
    log.info('Retrieving existing Subnet information')
    v.subnets = vpc_connection.get_all_subnets(filters={'vpcId': v.id})
    log.info('Discovered {0} subnets in the VPC'.format(len(v.subnets)))

    # If the number of subnets discivered for this VPC is 0 then something is wrong,
    # most likely is that the wrong VPC has been specified.
    if len(v.subnets) == 0:
        log.error('No subnets found in the specified VPC after filtering. Have you specified the correct VPC?')
        clean_up(-1)

    # Now build a mapping table of subnet-name to subnet-id
    log.debug('Building subnet mapping table')
    _mLUT_SUBNETS = {}
    for s in v.subnets:
        try:
            name = s.tags['Name']
        except KeyError:
            log.warning('Found a subnet [{0}] with no Name tag'.format(s.id))
            continue

        _mLUT_SUBNETS[name] = {"id": s.id, "az": s.availability_zone.strip(os.getenv('AWS_DEFAULT_REGION')) }
        log.debug('Adding subnet mapping for {0} -> {1}'.format(name, s.id))

    # Check for Subnets
    try:
        log.debug('Searching for valid mapping in provided subnets')
        [ _mLUT_SUBNETS[s] for s in subnet_names ]
    except KeyError:
        log.error('Subnet [{0}] not found in VPC [{1}]'.format(s, v.id))
        clean_up(-1)

    log.info('Found mappings for all ({0}) specified subnet names'.format(len(subnet_names)))
    return _mLUT_SUBNETS, v


def load_markdown_table(filename):
    """Loads a valid Markdown syntax table into an array of dictionaries, with
    each row represented by a list of tuples"""

    with open(filename, 'r') as f:
        tuples = [ line.strip() for line in f if line.strip() ]

    # Remove comments
    tuples = [ line for line in  tuples if not line.startswith("#") ]

    # Remove the lines containing formatting only text
    tuples = [ line for line in  tuples if not line.startswith("|:") ]
    tuples = [ line for line in  tuples if not line.startswith("| :") ]

    # Assume the first 'row' contains the column names
    col_names = [ x.strip() for x in tuples[0].split('|') if x != '' ]
    log.debug('Parsed {0} column names'.format(len(col_names)))
    tuples.pop(0)

    instances = []
    for row in tuples:
        values = [ x.strip() for x in row.split('|') if x != '' ]

        instance = {}
        for idx in range(0, len(col_names)):
            key_name = col_names[idx]

            # If we won't have a value for a specific key-name then default to ''
            try:
                key_value = values[idx]
            except IndexError:
                key_value = ''

            instance[key_name] = key_value

        # log.debug('Parsed Row {0}'.format(instance))
        instances.append(instance)

    log.debug('Parsed {0} instance sets for building'.format(len(instances)))
    return instances


def setup_logging(logfile=None, verbose=False):

    if logfile:
        if os.path.exists(os.path.dirname(logfile)):

            # Setup default file logging and set the handler to recieve everything
            fh = logging.FileHandler(logfile)
            fh.setFormatter(logging.Formatter(CONST_LOG_FORMAT_FILE))
            fh.setLevel(logging.INFO)
            log.addHandler(fh)
        else:

            raise (
                "log directory does not exist ("
                + os.path.dirname(logfile)
                + ")")

            clean_up(-1)

    # Add a log handler for stdout and set the handler to recieve everything
    csh = RainbowLoggingHandler(sys.stderr, color_funcName=('black', 'yellow', True))
    csh.setFormatter(logging.Formatter(CONST_LOG_FORMAT_CONSOLE))
    csh.setLevel(logging.DEBUG)
    log.addHandler(csh)

    # Now set the root logger to INFO
    log.setLevel(logging.INFO)

    # Check for verbose logging enabled
    if verbose is True:
        log.setLevel(logging.DEBUG)
        if logfile:
            fh.setLevel(logging.DEBUG)
        csh.setLevel(logging.DEBUG)
        log.debug('Debug logging enabled')
    return log


def connect_to_aws(command_line_options):
    global _mLUT_INSTANCES
    global _mLUT_SUBNETS
    global _mLUT_SECURITY_GROUPS
    global _mEC2_PARAMS
    global _mAWS_VPC_CONN
    global _mAWS_EC2_CONN

    v = AWS_VPC()

    from awshutils.aws import mapper
    m = mapper.AwsResourceMapper()

    _mAWS_VPC_CONN = m.vpc_conn
    _mAWS_EC2_CONN = m.ec2_conn
    _mAWS_ELB_CONN = m.elb_conn
    v.region = m.aws_region
    v.id = command_line_options['--vpc-id']

    return v, _mAWS_VPC_CONN, _mAWS_EC2_CONN, _mAWS_ELB_CONN


def get_vpc_cidr_block(vpc_id, vpc_connection):
    vpc = vpc_connection.get_all_vpcs(vpc_ids=[vpc_id])[0]
    return vpc.cidr_block


def walk_level(some_dir, level=1):
    """Functions just like os.walk() but with the abaility to limit how many
    levels it traverses"""

    some_dir = some_dir.rstrip(os.path.sep)
    assert os.path.isdir(some_dir)
    num_sep = some_dir.count(os.path.sep)
    for root, dirs, files in os.walk(some_dir):
        yield root, dirs, files
        num_sep_this = root.count(os.path.sep)
        if num_sep + level <= num_sep_this:
            del dirs[:]



def list_environments():
    """List the available environments that can be used with cloudbuilder"""

    global CONST_AWSH_ROOT

    env_root = CONST_AWSH_ROOT + '/etc/cloudbuilder'
    log.debug('Building list of environment names in {0}'.format(env_root))
    env_names = [ os.path.basename(x[0]) for x in walk_level(env_root, level=1) if not x[0] == env_root ]
    log.debug('Found possible environments: {0}'.format(env_names))

    validation_text = FG.RED + 'Basic checks failed' + STYLE.RESET_ALL

    for env_name in env_names:
        log.debug('Performing basic checking on {0}'.format(env_name))
        file_params = env_root + '/' + env_name + '/params.ini'
        file_instances = env_root + '/' + env_name + '/instances.md'

        try:

            # Now check for the necessary files in the conf-dir and attempt to load them
            if os.path.exists(file_params) and os.path.exists(file_instances):
                load_params_file(file_params)
                load_markdown_table(file_instances)

                validation_text = FG.GREEN + 'Basic checks succeeded' + STYLE.RESET_ALL

        except AssertionError:
            pass

        log.info('Environment: {0:<30} ({1})'.format(env_name, validation_text))


def wait_while(instance, status):
    # Sleep initially in the event that we've just created the instance
    time.sleep(5)
    instance.update()
    while instance.state == status:
        time.sleep(5)
        instance.update()


def map_vpc_name_to_id(command_line_options, vpc):
    # Map the VPC-Name to a VpcId if provided
    if 'vpc-' not in command_line_options.vpc:
        log.info('Mapping VPC named [{0}] to VpcId'.format(command_line_options.vpc))
        vpcs = vpc.get_all_vpcs()
        for v in vpcs:
            try:
                name = v.tags['Name']
                if name.lower() == command_line_options.vpc.lower():
                    log.info('Matched {0} to VpcId {1}'.format(name, v.id))
                    return v.id
            except KeyError:
                log.warning('Found a VPC [{0}] with no Name tag'.format(v.id))
                continue
    else:
        return command_line_options.vpc


def ensure_args(args, expected_args=[]):
    for arg in args:
        if arg is None:
            log.error('Mandatory parameter not available! {} required'.format(','.join(expected_args)))
            clean_up(-1)


def map_sg_id_to_name(sg_id, sgs):
    # Map Security group id to security group name
    for sg in sgs:
        if sg_id == sg.id:
            return sg.tags.get("Name")


def str2bool(v):
    return v.lower() in ("yes", "true", "t", "1")


def clean_up(returnValue=0):
    sys.exit(returnValue)

def check_imports():
    # Check for Boto installation and correct version
    try:
        import boto
    except ImportError:
        print "The 'boto' module does not seem to be available, exiting."
        sys.exit(1)

    try:
        import colorama
    except ImportError:
        print "The 'colorama' module does not seem to be available, exiting."
        sys.exit(1)

    from distutils.version import StrictVersion
    if StrictVersion(boto.__version__) < StrictVersion(CONST_MIN_BOTO_VER):
        print 'Error: the boto package version should be at least: ' + \
            CONST_MIN_BOTO_VER + '; installed: ' + boto.__version__
        sys.exit(1)


def get_existing_sgs(v):
    log.info('Retrieving existing security group information')
    v.sgs = [ x for x in _mAWS_EC2_CONN.get_all_security_groups(filters={"vpc-id": v.id})]
    log.info('Discovered {0} existing security groups in VPC {1}'.format(len(v.sgs), v.id))
    return v


def exec_command(cmd, exit_on_fail=False, shell=False):
    args = shlex.split(cmd)
    try:
        process = subprocess.Popen(args, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, shell=shell)
    except OSError as(_, strerror):
        error = '  !!! Error executing command >' + cmd + ': ' + strerror
        return (None, error, 0)
    output, error = process.communicate()

    if process.returncode != 0 and exit_on_fail:
        print output
        print error
        sys.exit(1)

    return output, error, process.returncode


def flatten_mixed_list(l):
    for el in l:
        if isinstance(el, collections.Iterable) and not isinstance(el, basestring):
            for sub in flatten_mixed_list(el):
                yield sub
        else:
            yield el
