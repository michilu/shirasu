.SUFFIXES: .haml .html
.haml.html:
	haml -f html5 $< $@
HAML = $(wildcard haml/*.haml)
HTML = $(HAML:.haml=.html)

.SUFFIXES: .coffee .js
.coffee.js:
	coffee -c $<
COFFEE = $(wildcard coffee/*.coffee)
JS = $(COFFEE:.coffee=.js)

SRC:=coffee/
DST:=www/scripts/

all: html js

iterative:
	coffee -w -c -o $(DST) $(SRC) 2>&1

html:	$(HTML)
	@cp haml/*.html www/.

js: $(JS)
	@cp $(SRC)*.js $(DST).

clean:
	rm -rf haml/*.html
	rm -rf $(SRC)*.js
