from simpletal import simpleTAL, simpleTALES
import StringIO

def mktemplate (tmplFilename, encoding='utf-8'):
	tmplFile = file(tmplFilename)
	tmpl = simpleTAL.compileHTMLTemplate (tmplFile,inputEncoding=encoding)
	tmplFile.close()
	return tmpl

def serialize (tmpl, outfile=None, encoding='utf-8', **kwds):
	ctx = simpleTALES.Context (allowPythonPath=1)
	for k,v in kwds.items(): ctx.addGlobal (k, v)
	  # Use StringIO module because cStringIO does not do unicode.
	if outfile is None: ofl = StringIO.StringIO ()
	else: ofl = outfile
	tmpl.expand (ctx, ofl, outputEncoding=encoding)
	if not outfile: return ofl.getvalue
	return # None
