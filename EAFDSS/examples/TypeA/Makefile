# Install the data files at the correct places


all: ppd/openeafdss.ppd

clean:

install: ppd/openeafdss.ppd
	$(INSTALL_DATA) -D ppd/openeafdss.ppd $(DATADIR)/model/openeafdss.ppd
	
ppd/openeafdss.ppd: openeafdss.drv
	ppdc openeafdss.drv
#eof
