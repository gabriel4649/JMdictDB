# $Revision$
# $Date$

all: jelparse.py

jelparse.py: jelparse.y
	-rm jelparse_tab.py*
	python ../../tools/yply.py jelparse.y >jelparse.py
	python ../../tools/gen_parsetab.py 
	python -c "import jelparse_tab"

.DELETE_ON_ERROR:
