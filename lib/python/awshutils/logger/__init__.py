import os
import sys
import logging
from rainbow_logging_handler import RainbowLoggingHandler

_DEFAULT_LOG_FORMAT_FILE = '%(asctime)s %(levelname)-5.5s %(module)-10.10s:%(lineno)04.4d %(funcName)-25.25s %(message)s'
_DEFAULT_LOG_FORMAT_CONSOLE = '%(asctime)s %(lineno)04.4d %(levelname)-5.5s %(message)s'
_DEFAULT_LOG_LEVEL = logging.INFO

LOG_CONTEXT = 'awshutils'


class NullHandler(logging.Handler):
    def emit(self, record):
        pass


class AWSHLog(object):
    '''Wrapper for consistent logging across various AWSH utils'''

    def __init__(self, context=LOG_CONTEXT, level=_DEFAULT_LOG_LEVEL, log_format_string=_DEFAULT_LOG_FORMAT_FILE, console_format_string=_DEFAULT_LOG_FORMAT_CONSOLE):
        self.context = os.path.basename(context)
        self.logger = logging.getLogger(LOG_CONTEXT)
        self.file_handler = None
        self.console_handler = None
        self.cloud_handler = None

        AWSH_ROOT = os.getenv('AWSH_ROOT', '/tmp')
        log_filename = '{}/log/{}.log'.format(AWSH_ROOT, self.context)

        if os.path.exists(os.path.dirname(log_filename)):

            if self.file_handler is None:
                # Setup default file logging and set the handler to recieve everything
                fh = logging.FileHandler(log_filename)
                fh.setFormatter(logging.Formatter(log_format_string))
                fh.setLevel(level)
                self.logger.addHandler(fh)
                self.file_handler = fh

            if self.console_handler is None:
                # Add a log handler for stdout and set the handler to recieve everything
                csh = RainbowLoggingHandler(sys.stderr, color_funcName=('black', 'yellow', True))
                csh.setFormatter(logging.Formatter(console_format_string))
                csh.setLevel(level)
                self.logger.addHandler(csh)
                self.console_handler = csh

            # Now set the root logger to the specified level
            logging.getLogger(LOG_CONTEXT).setLevel(level)

        else:
            # If logging can't be initialised we need to exit on the assumption
            # that we should not run without audit logging at the very least
            m = 'log directory does not exist {}'.format(os.path.dirname(log_filename))
            raise IOError(m)
            exit(1)

    def setLevel(self, level):
        logging.getLogger(LOG_CONTEXT).setLevel(level)
        self.file_handler.setLevel(level)
        self.console_handler.setLevel(level)

    def info(self, msg, *args, **kwargs):
        self.logger.info(msg, *args, **kwargs)

    def debug(self, msg, *args, **kwargs):
        self.logger.debug(msg, *args, **kwargs)

    def error(self, msg, *args, **kwargs):
        self.logger.error(msg, *args, **kwargs)

    def warn(self, msg, *args, **kwargs):
        self.logger.warning(msg, *args, **kwargs)

    def warning(self, msg, *args, **kwargs):
        self.logger.warning(msg, *args, **kwargs)

    def critical(self, msg, *args, **kwargs):
        self.logger.critical(msg, *args, **kwargs)


log = logging.getLogger(LOG_CONTEXT)
log.addHandler(NullHandler())
