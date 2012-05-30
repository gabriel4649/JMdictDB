import exceptions, re
from .odict import odict

class Error(Exception):
    """Base class for ConfigParser exceptions."""

class ParseError(Error):
    """Raised when a configuration file does not follow legal syntax."""
    def __init__(self, filename):
        Error.__init__(self, 'Config text contains syntax errors: %s' % filename)
        self.filename = filename
        self.errors = []
    def append(self, lineno, line):
        self.errors.append((lineno, line))
        self.args = self.args[0] = self.args[0] + '\n\t[line %2d]: %s' % (lineno, line)

class NoSectionError(Error):
    """Raised when no section matches a requested option."""
    def __init__(self, section):
        Error.__init__(self, 'No section: %r' % (section,))
        self.section = section

class MissingSectionHeaderError(ParseError):
    """Raised when a key-value pair is found before any section header."""
    def __init__(self, filename, lineno, line):
        Error.__init__(
            self,
            'File contains no section headers.\nfile: %s, line: %d\n%r' %
            (filename, lineno, line))
        self.filename = filename
        self.lineno = lineno
        self.line = line

DEFAULTSECT = '# FIXME'

class Config (odict):
    def __init__ (self, fn_or_iter=None, option_name_case=None):
          # 'fn_or_iter'
          #   If a string, will be used as a filename to open and read.
          #   Otherwise will be iterated to get lines of the ini file data.
          # 'option_name_case' is one of:
          #   "u" -- Convert option names to upper case.
          #   "l" -- Convert option names to lower case.
          #   "c"-- Call optionxform() to get option names.
          #   anything else -- Use option names as-is.

        odict.__init__ (self)
        self.option_name_case = option_name_case
        self.blank_line_between_sections = True
        self.start_multiline_opt_on_new_line = False
        self.line_terminator = '\n'
        if fn_or_iter:
            if isinstance (fn_or_iter, str):
                fl = open (fn_or_iter)
                fname = fn_or_iter
            else:
                fl = fn_or_iter
                fname = None
            self.read (fl, fname)

    # Following stolen from the Python-2.5.1 ConfigParser module.
    # Regular expressions for parsing section headers and options.
    SECTCRE = re.compile(
        r'\['                                 # [
        r'(?P<header>[^]]+)'                  # very permissive!
        r'\]'                                 # ]
        )
    OPTCRE = re.compile(
        r'(?P<option>[^:=\s][^:=]*)'          # very permissive!
        r'\s*(?P<vi>[:=])\s*'                 # any number of space/tab,
                                              # followed by separator
                                              # (either : or =), followed
                                              # by any # space/tab
        r'(?P<value>.*)$'                     # everything up to eol
        )

    def read(self, iterable, fpname=None):
        """Parse a sectioned setup file.

        The sections in setup file contains a title line at the top,
        indicated by a name in square brackets (`[]'), plus key/value
        options lines, indicated by `name: value' format lines.
        Continuations are represented by an embedded newline then
        leading whitespace.  Blank lines, lines beginning with a '#',
        and just about everything else are ignored.
        """
        cursect = None                            # None, or a dictionary
        optname = None
        lineno = 0
        e = None                                  # None, or an exception
        for line in iterable:
            lineno = lineno + 1
            line = line.rstrip()
            # comment or blank line?
            if line == '' or re.search (r'^((\s*[#;])|(rem\s))', line, re.I):
                continue
            # continuation line?
            if line[0].isspace() and cursect is not None and optname:
                value = re.sub (r'^((\t)|([ ]{1,8}))', '', line)
                cursect[optname] = "%s\n%s" % (cursect[optname], value)
            # a section header or option header?
            else:
                # is it a section header?
                mo = self.SECTCRE.match(line)
                if mo:
                    sectname = mo.group('header')
                    if sectname in self:
                        cursect = self[sectname]
                    elif sectname == DEFAULTSECT:
                        cursect = self._defaults
                    else:
                        cursect = odict (__name__=sectname)
                        self[sectname] = cursect
                    # So sections can't start with a continuation line
                    optname = None
                # no section header in the file?
                elif cursect is None:
                    raise MissingSectionHeaderError(fpname, lineno, line)
                # an option line?
                else:
                    mo = self.OPTCRE.match(line)
                    if mo:
                        optname, vi, optval = mo.group('option', 'vi', 'value')
                        if vi in ('=', ':') and ';' in optval:
                            # ';' is a comment delimiter only if it follows
                            # a spacing character
                            pos = optval.find(';')
                            if pos != -1 and optval[pos-1].isspace():
                                optval = optval[:pos]
                        optval = optval.strip()
                        # allow empty values
                        if optval == '""':
                            optval = ''
                        optname = optname.rstrip()
                        if   self.option_name_case == "lower":  optname = optname.lower()
                        elif self.option_name_case == "upper":  optname = optname.upper()
                        elif self.option_name_case == "custom": optname = self.optionxform (optname)
                        cursect[optname] = optval
                    else:
                        # a non-fatal parsing error occurred.  set up the
                        # exception but keep going. the exception will be
                        # raised at the end of the file and will contain a
                        # list of all bogus lines
                        if not e:
                            e = ParseError(fpname)
                        e.append(lineno, repr(line))
        # if any parsing errors occurred, raise an exception
        if e:
            raise e

    def write (self):
        """Generator that yields lines of the .ini-format representation
           of the configuration state."""
        first = True;  lt = self.line_terminator
        for sect_name, opts in list(self.items()):
            if not first and self.blank_line_between_sections: yield lt
            first = False
            for s in self._writesec (sect_name, opts):
                yield s + lt

    def _writesec (self, name, opts):
        yield "[%s]" % name
        for (key, value) in list(opts.items()):
            if key == "__name__": continue
            lines = str(value).splitlines()
            if self.start_multiline_opt_on_new_line and len(lines) > 1:
                yield "%s =" % key
                yield "\t%s" % lines[0]
            else: yield "%s = %s" % (key, lines[0])
            if len(lines) > 1:
                for line in lines[1:]: yield "\t%s" % line

    def optionxform(self, optionstr):
        return optionstr.lower()

