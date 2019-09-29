# Header will go here when ready to publish
"""
A simple library of AWS utility functions that are used regularly by AWSH tools
"""

import os
import sys
import logging
from awshutils.logger import LOG_CONTEXT
from awshutils import clean_up, CONST_AWSH_ROOT, check_imports

###############################################################################
# CONFIG - Begin
###############################################################################

CONST_AWS_ENV_VARIABLE_NAMES = [
    'AWS_DEFAULT_REGION',
    'AWS_ACCESS_KEY_ID',
    'AWS_SECRET_ACCESS_KEY'
]


###############################################################################
# CONFIG - End (Do Not Edit Below)
###############################################################################

check_imports()
_log = logging.getLogger(LOG_CONTEXT)

from boto import ec2, vpc, iam
from boto.ec2 import elb
from boto.vpc import VPCConnection
import boto.ec2.networkinterface
from boto.route53 import Route53Connection
from boto.ec2 import cloudwatch

###############################################################################
# Classes
###############################################################################


class AwsResourceMapper():
    '''Helper class for mapping AWS ids to 'Name' tags and vice-versa
    eg.
        instance-id i-b6b075f5 --> dv-lx-ihsweb-02.dev.abc.cloud.org.ie
        vpc name 'DEV'         --> vpc-id vpc-63ad4d04
        vpc-id vpc-63ad4d04    --> DEV
    '''

    def __init__(self):
        self.resources = _initialise_aws_connections()
        # VPC lookup tables
        self.lut_vpc_name_to_id = None
        self.lut_vpc_name_to_vpc = None
        self.lut_vpc_id_to_name = None
        self.lut_vpc_id_to_vpc = None
        # Instance lookup tables
        self.lut_instance_name_to_id = None
        self.lut_instance_name_to_instance = None
        self.lut_instance_id_to_name = None
        self.lut_instance_id_to_instance = None
        # ELB lookup tables
        self.lut_elb_name_to_id = None
        self.lut_elb_name_to_elb = None
        self.lut_elb_id_to_name = None
        self.lut_elb_id_to_elb = None
        # SG lookup tables
        self.lut_sg_name_to_id = None
        self.lut_sg_name_to_sg = None
        self.lut_sg_id_to_name = None
        self.lut_sg_id_to_sg = None
        # Subnet lookup tables
        self.lut_subnet_name_to_id = None
        self.lut_subnet_name_to_subnet = None
        self.lut_subnet_id_to_name = None
        self.lut_subnet_id_to_subnet = None

    def get_resources(self):
        '''Returns a dictionary of the initialised AWS resources'''
        return self.resources

    def vpc_name_to_id(self, vpc_name):
        '''Attempts to map a given vpc 'Name' tag to a VPC id, returning None if not found'''

        if self.lut_vpc_name_to_id is None:
            self.lut_vpc_name_to_id, self.lut_vpc_name_to_vpc, self.lut_vpc_id_to_name, self.lut_vpc_id_to_vpc = self._get_vpc_luts()

        try:
            r = self.lut_vpc_name_to_id[vpc_name.lower()]
        except KeyError:
            r = None

        return r

    def vpc_name_to_vpc(self, vpc_name):
        '''Attempts to map a given vpc 'Name' tag to a VPC, returning None if not found'''

        if self.lut_vpc_name_to_vpc is None:
            self.lut_vpc_name_to_id, self.lut_vpc_name_to_vpc, self.lut_vpc_id_to_name, self.lut_vpc_id_to_vpc = self._get_vpc_luts()

        try:
            r = self.lut_vpc_name_to_vpc[vpc_name.lower()]
        except KeyError:
            r = None

        return r

    def vpc_id_to_name(self, vpc_id):
        '''Attempts to map a given vpc id to a 'Name' tag, returning None if not found'''

        if self.lut_vpc_id_to_name is None:
            self.lut_vpc_name_to_id, self.lut_vpc_name_to_vpc, self.lut_vpc_id_to_name, self.lut_vpc_id_to_vpc = self._get_vpc_luts()

        try:
            r = self.lut_vpc_id_to_name[vpc_id]
        except KeyError:
            r = None

        return r

    def vpc_id_to_vpc(self, vpc_id):
        '''Attempts to map a given vpc id to a VPC, returning None if not found'''

        if self.lut_vpc_id_to_vpc is None:
            self.lut_vpc_name_to_id, self.lut_vpc_name_to_vpc, self.lut_vpc_id_to_name, self.lut_vpc_id_to_vpc = self._get_vpc_luts()

        try:
            r = self.lut_vpc_id_to_vpc[vpc_id]
        except KeyError:
            r = None

        return r

    def _get_vpc_luts(self):
        '''Returns a set of LUTs of vpc-ids to names and vpc-names to vpc-ids'''

        names_to_ids = {}
        names_to_vpcs = {}
        ids_to_names = {}
        ids_to_vpcs = {}

        _log.debug('Retrieving VPC information')
        vpcs = self.resources['vpc'].get_all_vpcs()
        _log.debug('Discovered {0} VPCs'.format(len(vpcs)))

        for v in vpcs:

            try:
                vpc_name = v.tags['Name'].lower()
                names_to_ids[vpc_name] = v.id
                names_to_vpcs[vpc_name] = v
                ids_to_names[v.id] = vpc_name
                ids_to_vpcs[v.id] = v

            except KeyError:
                _log.warning('Found a VPC [{0}] with no Name tag'.format(v.id))

        return names_to_ids, names_to_vpcs, ids_to_names, ids_to_vpcs

    def instance_name_to_id(self, instance_name):
        '''Attempts to map a given instance 'Name' tag to an instance id, returning None if not found'''

        if self.lut_instance_name_to_id is None:
            self.lut_instance_name_to_id, self.lut_instance_name_to_instance, self.lut_instance_id_to_name, self.lut_instance_id_to_instance = self._get_instance_luts()

        try:
            r = self.lut_instance_name_to_id[instance_name.lower()]
        except KeyError:
            r = None

        return r

    def instance_name_to_instance(self, instance_name):
        '''Attempts to map a given instance 'Name' tag to an instance, returning None if not found'''

        if self.lut_instance_name_to_instance is None:
            self.lut_instance_name_to_id, self.lut_instance_name_to_instance, self.lut_instance_id_to_name, self.lut_instance_id_to_instance = self._get_instance_luts()

        try:
            r = self.lut_instance_name_to_instance[instance_name.lower()]
        except KeyError:
            r = None

        return r

    def instance_id_to_name(self, instance_id):
        '''Attempts to map a given instance id to an instance 'Name' tag, returning None if not found'''

        if self.lut_instance_id_to_name is None:
            self.lut_instance_name_to_id, self.lut_instance_name_to_instance, self.lut_instance_id_to_name, self.lut_instance_id_to_instance = self._get_instance_luts()

        try:
            r = self.lut_instance_id_to_name[instance_id.lower()]
        except KeyError:
            r = None

        return r

    def instance_id_to_instance(self, instance_id):
        '''Attempts to map a given instance id to an instance, returning None if not found'''

        if self.lut_instance_id_to_instance is None:
            self.lut_instance_name_to_id, self.lut_instance_name_to_instance, self.lut_instance_id_to_name, self.lut_instance_id_to_instance = self._get_instance_luts()

        try:
            r = self.lut_instance_id_to_instance[instance_id.lower()]
        except KeyError:
            r = None

        return r

    def _get_instance_luts(self):
        '''Returns a set of LUTs of instance-ids to names and instance-names to ids'''

        names_to_ids = {}
        names_to_instances = {}
        ids_to_names = {}
        ids_to_instances = {}

        _log.info('Retrieving Instance information')
        reservations = self.resources['ec2'].get_all_reservations()
        instances = [ i for r in reservations for i in r.instances ]
        _log.debug('Discovered {0} instances'.format(len(instances)))

        for i in instances:

            try:
                instance_name = i.tags['Name'].lower()
                names_to_ids[instance_name] = i.id
                names_to_instances[instance_name] = i
                ids_to_names[i.id] = instance_name
                ids_to_instances[i.id] = i
            except KeyError:
                _log.warning('Found an instance [{0}] with no Name tag'.format(i.id))

        return names_to_ids, names_to_instances, ids_to_names, ids_to_instances

    def sg_name_to_id(self, sg_name):
        '''Attempts to map a given sg 'Name' tag to an sg id, returning None if not found'''

        if self.lut_sg_name_to_id is None:
            self.lut_sg_name_to_id, self.lut_sg_name_to_sg, self.lut_sg_id_to_name, self.lut_sg_id_to_sg = self._get_sg_luts()

        try:
            r = self.lut_sg_name_to_id['{}'.format(sg_name).lower()]
        except KeyError:
            r = None

        return r

    def sg_name_to_sg(self, sg_name):
        '''Attempts to map a given sg 'Name' tag to an sg, returning None if not found'''

        if self.lut_sg_name_to_sg is None:
            self.lut_sg_name_to_id, self.lut_sg_name_to_sg, self.lut_sg_id_to_name, self.lut_sg_id_to_sg = self._get_sg_luts()

        try:
            r = self.lut_sg_name_to_sg['{}'.format(sg_name).lower()]
        except KeyError:
            r = None

        return r

    def sg_id_to_name(self, sg_id):
        '''Attempts to map a given sg id to an sg 'Name' tag, returning None if not found'''

        if self.lut_sg_id_to_name is None:
            self.lut_sg_name_to_id, self.lut_sg_name_to_sg, self.lut_sg_id_to_name, self.lut_sg_id_to_sg = self._get_sg_luts()

        try:
            r = self.lut_sg_id_to_name['{}'.format(sg_id).lower()]
        except KeyError:
            r = None

        return r

    def sg_id_to_sg(self, sg_id):
        '''Attempts to map a given sg id to an sg, returning None if not found'''

        if self.lut_sg_id_to_sg is None:
            self.lut_sg_name_to_id, self.lut_sg_name_to_sg, self.lut_sg_id_to_name, self.lut_sg_id_to_sg = self._get_sg_luts()

        try:
            r = self.lut_sg_id_to_sg['{}'.format(sg_id).lower()]
        except KeyError:
            r = None

        return r

    def _get_sg_luts(self):
        '''Returns a set of LUTs of sg-ids to names and sg-names to ids'''

        names_to_ids = {}
        names_to_sgs = {}
        ids_to_names = {}
        ids_to_sgs = {}

        _log.info('Retrieving SG information')
        sgs = self.resources['ec2'].get_all_security_groups()
        _log.debug('Discovered {0} sgs'.format(len(sgs)))

        for s in sgs:

            try:
                sg_name = s.tags['Name'].lower()
                names_to_ids[sg_name] = s.id
                names_to_sgs[sg_name] = s
                ids_to_names[s.id] = sg_name
                ids_to_sgs[s.id] = s
            except KeyError:
                # If the SG has no 'Name' tag then we'll use the 'GroupName' tag
                # instead...fugly.
                _log.warning('Found an sg [{0}] with no Name tag'.format(s.id))
                sg_name = s.name.lower()
                names_to_ids[sg_name] = s.id
                names_to_sgs[sg_name] = s
                ids_to_names[s.id] = sg_name
                ids_to_sgs[s.id] = s

        return names_to_ids, names_to_sgs, ids_to_names, ids_to_sgs

    def subnet_name_to_id(self, subnet_name):
        '''Attempts to map a given subnet 'Name' tag to an subnet id, returning None if not found'''

        if self.lut_subnet_name_to_id is None:
            self.lut_subnet_name_to_id, self.lut_subnet_name_to_subnet, self.lut_subnet_id_to_name, self.lut_subnet_id_to_subnet = self._get_subnet_luts()

        try:
            r = self.lut_subnet_name_to_id[subnet_name.lower()]
        except KeyError:
            r = None

        return r

    def subnet_name_to_subnet(self, subnet_name):
        '''Attempts to map a given subnet 'Name' tag to an subnet, returning None if not found'''

        if self.lut_subnet_name_to_subnet is None:
            self.lut_subnet_name_to_id, self.lut_subnet_name_to_subnet, self.lut_subnet_id_to_name, self.lut_subnet_id_to_subnet = self._get_subnet_luts()

        try:
            r = self.lut_subnet_name_to_subnet[subnet_name.lower()]
        except KeyError:
            r = None

        return r

    def subnet_id_to_name(self, subnet_id):
        '''Attempts to map a given subnet id to an subnet 'Name' tag, returning None if not found'''

        if self.lut_subnet_id_to_name is None:
            self.lut_subnet_name_to_id, self.lut_subnet_name_to_subnet, self.lut_subnet_id_to_name, self.lut_subnet_id_to_subnet = self._get_subnet_luts()

        try:
            r = self.lut_subnet_id_to_name[subnet_id.lower()]
        except KeyError:
            r = None

        return r

    def subnet_id_to_subnet(self, subnet_id):
        '''Attempts to map a given subnet id to an subnet, returning None if not found'''

        if self.lut_subnet_id_to_subnet is None:
            self.lut_subnet_name_to_id, self.lut_subnet_name_to_subnet, self.lut_subnet_id_to_name, self.lut_subnet_id_to_subnet = self._get_subnet_luts()

        try:
            r = self.lut_subnet_id_to_subnet[subnet_id.lower()]
        except KeyError:
            r = None

        return r

    def _get_subnet_luts(self):
        '''Returns a set of LUTs of subnet-ids to names and subnet-names to ids'''

        names_to_ids = {}
        names_to_subnets = {}
        ids_to_names = {}
        ids_to_subnets = {}

        _log.info('Retrieving Subnet information')
        subnets = self.resources['vpc'].get_all_subnets()
        _log.debug('Discovered {0} subnets'.format(len(subnets)))

        for s in subnets:

            try:
                subnet_name = s.tags['Name'].lower()
                names_to_ids[subnet_name] = s.id
                names_to_subnets[subnet_name] = s
                ids_to_names[s.id] = subnet_name
                ids_to_subnets[s.id] = s
            except KeyError:
                # If the SG has no 'Name' tag then we'll use the 'GroupName' tag
                # instead...fugly.
                _log.warning('Found a subnet [{0}] with no Name tag'.format(s.id))
                subnet_name = s.id
                names_to_ids[subnet_name] = s.id
                names_to_subnets[subnet_name] = s
                ids_to_names[s.id] = subnet_name
                ids_to_subnets[s.id] = s

        return names_to_ids, names_to_subnets, ids_to_names, ids_to_subnets


def _validate_environment():
    '''Attempts to to basic validation of the user's environment to ensure
    that the necessaru env variables are present'''

    # Make sure we have AWSH_ROOT before going any further
    if CONST_AWSH_ROOT is None:
        _log.error('The AWSH_ROOT environment variable was not found. Try not being an idiot.')
        sys.exit(1)

    for env_var_name in CONST_AWS_ENV_VARIABLE_NAMES:
        _log.debug('Checking for {0} in env'.format(env_var_name))
        if os.getenv(env_var_name, None) is None:
            _log.error('The environment variable {0} was not found. Make sure you load_aws_credentials first'.format(env_var_name))
            sys.exit(1)


def _initialise_aws_connections():
    _log.info('Initialising AWS Connections')

    _validate_environment()

    # Even though the Boto lib can use the environment variables we'll import one
    # for easier re-use in this script
    _log.info('Loading credentials from Environment')
    aws_region = os.getenv('AWS_DEFAULT_REGION')

    _log.info('Initializing Boto resources')
    resources = {
        'vpc': vpc.connect_to_region(aws_region),
        'ec2': ec2.connect_to_region(aws_region),
        'elb': elb.connect_to_region(aws_region),
        'iam': iam.connect_to_region(aws_region),
        'route53': Route53Connection(),
        'cloudwatch': cloudwatch.connect_to_region(aws_region),
        'region': aws_region
    }

    return resources
