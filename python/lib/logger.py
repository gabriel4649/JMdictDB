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

import sys, logging; L = logging.getLogger;

def log_config (level="debug", filename=None):
        """
        level -- One of: "critical", "error", "warning", "info", "debug".
        filename -- If not given or None, logging messages will be written 
          to sys.stderr.  Otherwise the name of a file to which the logging
          messages will be appended. 
        """

        if filename: msgdest = {'filename': filename }
        else:        msgdest = {'stream': sys.stderr}
        lvl = logging.getLevelName (level.upper())
        if not isinstance (lvl, int): raise ValueError ("bad 'level' parameter: %s" % level)
        logging.basicConfig (
            level=lvl,
            format='%(asctime)s %(levelname)1.1s [%(process)d] %(name)s: %(message)s',
            datefmt="%y%m%d-%H%M%S",
              # When both "stream" and "filename" are present and non-None, 
              # "filename" takes precedence according to 
            **msgdest)

          # Set the logging levels for the simpleTAL package to a minimum 
          # of WARNING (their DEBUG messages are voluminous.)
        for pkg in ("simpleTAL", "simpleTALES"):
            logging.getLogger (pkg).setLevel (max (lvl, logging.WARNING))

# The function L() is exported to provide callers with a consise way to
# write logging calls.  It is used like:
#
#   L('logger_name').info("log message...")
#  
__all__ = ['log_config', 'L']
