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


class CallerInfoFormatter(logging.Formatter):
    def format(self, record):
        if record.funcName == '<module>':
            record.funcName = '__main__'
        return super().format(record)


class AWSHLog(logging.Logger):
    '''Wrapper for consistent logging across various AWSH utils'''

    def __init__(self, context=LOG_CONTEXT, level=_DEFAULT_LOG_LEVEL,
                 log_format_string=_DEFAULT_LOG_FORMAT_FILE,
                 console_format_string=_DEFAULT_LOG_FORMAT_CONSOLE):
        self.context = os.path.basename(context)
        super().__init__(LOG_CONTEXT)
        self.file_handler = None
        self.console_handler = None
        self.cloud_handler = None

        AWSH_ROOT = os.getenv('AWSH_ROOT', '/tmp')
        AWSH_LOG_ROOT = os.getenv('HOME', '/tmp')
        log_filename = '{}/.awsh/log/{}.log'.format(AWSH_LOG_ROOT, self.context)

        if os.path.exists(os.path.dirname(log_filename)):

            if self.file_handler is None:
                # Setup default file logging and set the handler to receive everything
                fh = logging.FileHandler(log_filename)
                fh.setFormatter(CallerInfoFormatter(log_format_string))
                fh.setLevel(level)
                self.addHandler(fh)
                self.file_handler = fh

            if self.console_handler is None:
                # Add a log handler for stdout and set the handler to receive everything
                csh = RainbowLoggingHandler(sys.stderr, color_funcName=('black', 'yellow', True))
                csh.setFormatter(CallerInfoFormatter(console_format_string))
                csh.setLevel(level)
                self.addHandler(csh)
                self.console_handler = csh

            # Now set the root logger to the specified level
            logging.getLogger(LOG_CONTEXT).setLevel(level)

        else:
            # If logging can't be initialized we need to exit on the assumption
            # that we should not run without audit logging at the very least
            m = 'log directory does not exist {}'.format(os.path.dirname(log_filename))
            raise IOError(m)
            exit(1)

    def setLevel(self, level):
        logging.getLogger(LOG_CONTEXT).setLevel(level)
        self.file_handler.setLevel(level)
        self.console_handler.setLevel(level)


log = AWSHLog(LOG_CONTEXT)
log.addHandler(NullHandler())
