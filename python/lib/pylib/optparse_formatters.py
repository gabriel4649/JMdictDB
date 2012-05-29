from optparse import IndentedHelpFormatter
import textwrap

# This is a modified version of the formatter supplied with Optparse
# in the Python Standard Library.  If preserves paragraph breaks (two
# consecutive '\n's) which the standard optparse formatter doesn't do.
# It is based on a posting to comp.lang.python:
#
#   From: Dan <thermostat@gmail.com>
#   Newsgroups: comp.lang.python
#   Subject: Re: optparse help output
#   Date: Wed, 24 Oct 2007 17:26:03 -0000
#   Message-ID: <1193246763.834306.68660@i13g2000prf.googlegroups.com>

class IndentedHelpFormatterWithNL (IndentedHelpFormatter):
    def _format_text(self, text):
        """
        Format a paragraph of free-form text for inclusion in the
        help output at the current indentation level.
        """
        text_width = self.width - self.current_indent
        indent = " "*self.current_indent
    # Code in this method above this line is the same as in Python 2.5 Optparse.
        lines = []
        cleaned = "\n".join ([x.strip() for x in text.split ("\n")])
        for para in cleaned.split("\n\n"):
            lines.extend (textwrap.wrap (para, text_width,
                                         initial_indent=indent,
                                         subsequent_indent=indent))
            # for each paragraph, keep the double newlines.
            if len (lines): lines[-1] += "\n"
        return '\n'.join (lines)

    def format_option(self, option):
        # The help for each option consists of two parts:
        #   * the opt strings and metavars
        #     eg. ("-x", or "-fFILENAME, --file=FILENAME")
        #   * the user-supplied help string
        #     eg. ("turn on expert mode", "read data from FILENAME")
        #
        # If possible, we write both of these on the same line:
        #   -x      turn on expert mode
        #
        # But if the opt string list is too long, we put the help
        # string on a second line, indented to the same column it would
        # start in if it fit on the first line.
        #   -fFILENAME, --file=FILENAME
        #           read data from FILENAME
        result = []
        opts = self.option_strings[option]
        opt_width = self.help_position - self.current_indent - 2
        if len(opts) > opt_width:
            opts = "%*s%s\n" % (self.current_indent, "", opts)
            indent_first = self.help_position
        else:                       # start help on same line as opts
            opts = "%*s%-*s  " % (self.current_indent, "", opt_width, opts)
            indent_first = 0
        result.append(opts)
        if option.help:
            #help_text = self.expand_default(option)
            help_text = option.help
    # Code in this method above this line is the same as in Python 2.5 Optparse.
            help_lines = []
            help_text = "\n".join([x.strip() for x in help_text.split("\n")])
            for para in help_text.split("\n\n"):
                help_lines.extend(textwrap.wrap(para, self.help_width))
                if len(help_lines):
                    # for each paragraph, keep the double newlines..
                    help_lines[-1] += "\n"
    # Code in this method below this line is the same as in Python 2.5 Optparse.
            result.append("%*s%s\n" % (indent_first, "", help_lines[0]))
            result.extend(["%*s%s\n" % (self.help_position, "", line)
                           for line in help_lines[1:]])
        elif opts[-1] != "\n":
            result.append("\n")
        return "".join(result)
