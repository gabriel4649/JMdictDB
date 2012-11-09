# $Revision$
# $Date$

all: jelparse.py

PYTHON = python3

jelparse.py jelparse_tab.py: jelparse.y
	-rm jelparse_tab.py*
	$(PYTHON) ../../tools/yply.py jelparse.y >jelparse.py
	$(PYTHON) ../../tools/gen_parsetab.py 
	$(PYTHON) -c "import jelparse_tab"
	-rm parsetab.py*

.DELETE_ON_ERROR:
