import os
import awshutils.aws.legacy.utils as utils
from awshutils.aws.legacy.utils import CONST_AWSH_ROOT, IterRegistry
from os import walk
from os.path import basename
import json
import configparser
from os.path import expanduser

# This should move to config (as in an actual config file...)

CONST_REL_CONFIG_DIR = expanduser('~/.cloudbuilder')


class ConfigObject(metaclass=IterRegistry):

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


class ConfigFile(object):
    def __init__(self, filename, ctype):
        self.filename = filename
        self.ctype = ctype
        self.basename = os.path.basename(filename)


class MarkdownConfig(ConfigFile):
    def parse(self):
        """Loads a valid Markdown syntax table into an array of dictionaries, with
        each row represented by a list of tuples"""

        with open(self.filename, 'r') as f:
            tuples = [line.strip() for line in f if line.strip()]

        # Remove comments
        tuples = [line for line in  tuples if not line.startswith("#")]

        # Remove the lines containing formatting only text
        tuples = [line for line in  tuples if not line.startswith("|:")]
        tuples = [line for line in  tuples if not line.startswith("| :")]

        # Assume the first 'row' contains the column names
        col_names = [x.strip() for x in tuples[0].split('|') if x != '']
        utils.log.debug('Parsed {0} column names'.format(len(col_names)))
        tuples.pop(0)

        instances = []
        for row in tuples:
            values = [x.strip() for x in row.split('|') if x != '']

            instance = {}
            for idx in range(0, len(col_names)):
                key_name = col_names[idx]

                # If we won't have a value for a specific key-name
                # then default to ''
                try:
                    key_value = values[idx]
                except IndexError:
                    key_value = ''

                if ',' in key_value:
                    key_value = [l.strip() for l in key_value.split(',')]

                instance[key_name] = key_value

            # log.debug('Parsed Row {0}'.format(instance))
            instances.append(instance)

        utils.log.debug('Parsed {0} instance sets for building'.format(len(instances)))
        self.parsed_file = instances
        return self.parsed_file


class IniConfig(ConfigFile):
    def parse(self):
        """Load params from the specificed filename and return the params as a
        dictionary"""

        utils.log.debug('Loading parms from {0}'.format(self.filename))

        config = configparser.ConfigParser()
        config.optionxform = str
        config.read(self.filename)

        object_list = config.sections()

        params = {}

        for config_object in object_list:

            o = ConfigObject(name=config_object)
            all_attributes = config.options(config_object)

            for attribute in all_attributes:

                value = config.get(config_object, attribute)
                # Replace the AWSH_ROOT variable with the current value if present
                value = value.replace('$AWSH_ROOT', CONST_AWSH_ROOT)

                utils.log.debug('ConfigObject[{0}] {1}: {2}'.format(config_object, attribute, value))
                o.add_property(attribute, value)

            params[o.name] = o

        self.parsed_file = params
        return self.parsed_file


class JSONConfig(ConfigFile):
    def parse(self):
        try:
            with open(self.filename, 'r') as json_file:
                return json.load(json_file)
        except Exception:
            return None


class ConfigManager(object):
    ''' Config Manager for Bob
        Handles the locating and parsing of varying bob config files
    '''
    def __init__(self, config_map, env_name=None, config_path=None):
        '''
        Find files for parsing.
        Either one of env_name or config_path should be set
        :param env_name Dir in $AWSH_ROOT/etc/cloudbuilder containing configs
        :param config_path Path in $AWSH_ROOT containing configs
        '''

        self.cfiles = {}
        self.configs = {}
        conf_dir = None
        if env_name:
            conf_dir = CONST_REL_CONFIG_DIR + '/' + env_name
        elif config_path:
            conf_dir = CONST_AWSH_ROOT + '/' + config_path

        if conf_dir:
            utils.log.debug('Searching for conf files in {0}'.format(conf_dir))
            files = []
            for root, _, fs in walk(conf_dir):
                for f in fs:
                    files.append("{}/{}".format(root, f))
            for f in files:
                _, ctype = f.split('.') if len(f.split('.')) == 2 else (None, None)
                if ctype in config_map.keys():
                    # config_map is a map of types to classes
                    # e.g. "md": MarkdownConfig
                    self.cfiles[basename(f)] = config_map[ctype](f, ctype)

    def parse_configs(self):
        for cfile in self.cfiles:
            self.configs[self.cfiles[cfile].basename] = self.cfiles[cfile].parse()

    def get_config(self, config_name):
        return self.configs.get(config_name)
