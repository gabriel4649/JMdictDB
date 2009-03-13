# $Revision$
# $Date$

all: jelparse.py

jelparse.py jelparse_tab.py: jelparse.y
	-rm jelparse_tab.py*
	python ../../tools/yply.py jelparse.y >jelparse.py
	python ../../tools/gen_parsetab.py 
	python -c "import jelparse_tab"
	-rm parsetab.py*

.DELETE_ON_ERROR:
