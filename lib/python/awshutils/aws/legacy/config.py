import os
from awshutils.aws.legacy.config_files import MarkdownConfig, IniConfig

# Global
CONST_MIN_BOTO_VER = '2.29.1'
CONST_DIR_TMP = "/tmp"
CONST_LOG_FORMAT_FILE = '%(asctime)s %(levelname)-5.5s %(module)s:%(lineno)04.4d %(funcName)-25.25s %(message)s'
CONST_LOG_FORMAT_CONSOLE = '%(asctime)s %(levelname)-5.5s %(message)s'
CONST_AWSH_ROOT = os.getenv('AWSH_ROOT', '')
CONFIG_TYPES = {'md': MarkdownConfig, 'ini': IniConfig}
