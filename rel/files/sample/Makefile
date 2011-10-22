.SUFFIXES: .haml .html
.haml.html:
	haml -f html5 $< $@
HAML = $(wildcard haml/*.haml)
HTML = $(HAML:.haml=.html)

SRC:=coffee/
DST:=www/scripts/
all:
	coffee -c -o $(DST) $(SRC)

iterative:
	coffee -w -c -o $(DST) $(SRC) 2>&1

html:	$(HTML)
	@cp haml/*.html www/.

clean:
	rm -rf haml/*.html
