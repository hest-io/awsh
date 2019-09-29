import os
import yaml
import logging
from awshutils.logger import LOG_CONTEXT
from awshutils import clean_up, CONST_AWSH_ROOT

_log = logging.getLogger(LOG_CONTEXT)


class IterRegistry(type):
    """Helper class for iteration through objects's properties"""

    def __iter__(self, cls):
        return iter(cls._registry)


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


def get_config_from_file(f, fmt=None):
    """Load params from the specified filename of format 'fmt' and return the
    config as a dictionary"""

    filename, file_extension = os.path.splitext(f)
    file_extension = file_extension.replace('.', '').lower()

    dispatch = {
        'ini': _get_config_from_ini_file,
        'yaml': _get_config_from_yaml_file,
        'yml': _get_config_from_yaml_file,
        'md': _get_config_from_markdown_file,
        'markdown': _get_config_from_markdown_file,
    }

    # Match on the provided format first
    if fmt in dispatch.keys():
        _log.debug('Loading file with specified format {}:{}'.format(fmt, f))
        return dispatch[fmt](f)

    # Try by file_extension next
    if file_extension in dispatch.keys():
        _log.debug('Loading file with format from file extension {}:{}'.format(file_extension, f))
        return dispatch[file_extension](f)

    # No match. Inform the user and exit
    _log.error('No parser configured for extension {}'.format(file_extension))
    clean_up(-1)


def _get_config_from_yaml_file(f):
    """Load params from the specified filename and return the params as a
    dictionary"""

    from os.path import expanduser
    filename = expanduser(f)

    _log.debug('Loading parms from {0}'.format(filename))
    with open(filename, 'r') as ymlfile:
        config = yaml.load(ymlfile)

    return config


def _get_config_from_ini_file(f):
    """Load params from the specified filename and return the params as a
    dictionary"""

    from os.path import expanduser
    filename = expanduser(f)

    _log.debug('Loading parms from {0}'.format(filename))

    import ConfigParser
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
            _log.debug('ConfigObject[{0}] {1}: {2}'.format(config_object, attribute, value))
            o.add_property(attribute, value)

        params[o.name] = o

    return params


def _get_config_from_markdown_file(f):
    '''Loads a valid Markdown syntax table into an array of dictionaries, with
    each row represented by a list of tuples'''

    with open(f, 'r') as fh:
        tuples = [line.strip() for line in fh if line.strip()]

    # Remove comments
    tuples = [line for line in tuples if not line.startswith("#")]

    # Remove the lines containing Markdown table formatting text
    tuples = [line for line in tuples if not line.startswith("|:")]
    tuples = [line for line in tuples if not line.startswith("| :")]

    # Assume the first 'row' contains the column names
    col_names = [x.strip() for x in tuples[0].split('|') if x != '']
    _log.debug('Parsed {0} column names'.format(len(col_names)))
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

        instances.append(instance)

    _log.debug('Parsed {0} instances for processing'.format(len(instances)))
    return instances
