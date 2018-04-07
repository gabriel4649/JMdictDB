#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2018 Stuart McGraw
#
#  JMdictDB is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 2 of the License,
#  or (at your option) any later version.
#
#  JMdictDB is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with JMdictDB; if not, write to the Free Software Foundation,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#######################################################################

# Provide a standard logging configuration for JMdictDB cgi scripts, 
# tools and library functions.

import sys, logging, traceback, os, datetime

# The function L() is a convenience function provided to importers
# as a consise way to write logging calls.  It is used like:
#   L('logger_name').info("log message...")

L = logging.getLogger;

def log_config (level="debug", filename=None):
        """
        level -- One of: "critical", "error", "warning", "info", "debug".
        filename -- If not given or None, logging messages will be written 
          to sys.stderr.  Otherwise the name of a file to which the logging
          messages will be appended.  If the file is not writable at the 
          time this function is called, a logging message will be written
          to stderr to that effect and further logging disabled.
        """
        msgdest, disable = {'stream': sys.stderr}, False
        if filename:
            if os.access (filename, os.W_OK):
                  # We should be able to set 'msgdest' below to simply:
                  #   {'filename': filename}
                  # However, it seems that when running as a cgi script under
                  # Apache-2.4, the file is opened with ascii encoding rather
                  # than utf-8.  When a logging message is written that contains
                  # non-ascii characters, a UnicodeEncodingError is raised.
                  # Curiously, the error and traceback is written to the web
                  # server log file and then control is returned to the python
                  # program that generated the message, which contrinues on 
                  # normally, though the original non-ascii log message never
                  # appears in the logging log file.  The following forces the
                  # logging file to be opened with utf-8 encoding.
                msgdest = {'handlers':
                           [logging.FileHandler(filename,'a','utf-8')] }
            else: disable = True
          # Allow logging levl to be either a number or a string ("debug", 
          # "error", etc: see the Python Logging module documentation.) 
        try: lvl = int(level)
        except ValueError: lvl = logging.getLevelName (level.upper())
        if not isinstance (lvl, int):
            raise ValueError ("bad 'level' parameter: %s" % level)
        logging.basicConfig (
            level=lvl,
            format='%(asctime)s %(levelname)1.1s [%(process)d] %(name)s: %(message)s',
            datefmt="%y%m%d-%H%M%S",
              # When both "stream" and "filename" are present and non-None, 
              # "filename" takes precedence according to 
            **msgdest)
        if disable:
            cwd = os.getcwd()
            L('logger').error(('Unable to write to logging file: %s'
                               '\n  (cwd: %s)') % (filename, cwd))
            logging.disable (logging.CRITICAL)

def handler( ex_cls, ex, tb ):
        import jmcgi
        errid = datetime.datetime.now().strftime("%y%m%d-%H%M%S")\
                + '-' + str(os.getpid())
        logging.critical( '{0}: {1}'.format(ex_cls, ex) )
        logging.critical( '\n' + ''.join( traceback.format_tb(tb)) )
        jmcgi.err_page( [str(ex)], errid )

def enable(): sys.excepthook = handler

__all__ = ['log_config', 'L']
